# frozen_string_literal: true

module Import
  class SourceUserPlaceholderReference < ApplicationRecord
    include BulkInsertSafe
    include EachBatch

    self.table_name = 'import_source_user_placeholder_references'

    belongs_to :source_user, class_name: 'Import::SourceUser'
    belongs_to :namespace

    validates :model, :namespace_id, :source_user_id, :user_reference_column, :alias_version, presence: true
    validates :numeric_key, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
    validates :composite_key,
      json_schema: { filename: 'import_source_user_placeholder_reference_composite_key' },
      allow_nil: true
    validate :validate_numeric_or_composite_key_present
    validate :validate_model_is_not_member

    attribute :composite_key, ::Gitlab::Database::Type::IndifferentJsonb.new

    scope :model_groups_for_source_user, ->(source_user) do
      where(source_user: source_user)
        .select(:model, :user_reference_column, :alias_version)
        .group(:model, :user_reference_column, :alias_version)
    end

    MODEL_BATCH_LIMIT = 500

    # If an element is ever added to this array, ensure that `.from_serialized` handles receiving
    # older versions of the array by filling in missing values with defaults. We'd keep that in place
    # for at least one release cycle to ensure backward compatibility.
    SERIALIZABLE_ATTRIBUTES = %w[
      composite_key
      model
      namespace_id
      numeric_key
      source_user_id
      user_reference_column
      alias_version
    ].freeze

    SerializationError = Class.new(StandardError)

    def aliased_model
      PlaceholderReferences::AliasResolver.aliased_model(model, version: alias_version)
    end

    def aliased_user_reference_column
      PlaceholderReferences::AliasResolver.aliased_column(model, user_reference_column, version: alias_version)
    end

    def aliased_composite_key
      composite_key.transform_keys do |key|
        PlaceholderReferences::AliasResolver.aliased_column(model, key, version: alias_version)
      end
    end

    def to_serialized
      Gitlab::Json.dump(attributes.slice(*SERIALIZABLE_ATTRIBUTES).to_h.values)
    end

    def model_record
      model_class = aliased_model

      model_relation = numeric_key? ? model_class.primary_key_in(numeric_key) : model_class.where(composite_key)
      model_relation.where({ aliased_user_reference_column => source_user.placeholder_user_id }).first
    end

    class << self
      def from_serialized(serialized_reference)
        deserialized = Gitlab::Json.parse(serialized_reference)

        raise SerializationError if deserialized.size != SERIALIZABLE_ATTRIBUTES.size

        attributes = SERIALIZABLE_ATTRIBUTES.zip(deserialized).to_h

        new(attributes.merge(created_at: Time.zone.now))
      end

      # Model relations are yielded in a block to ensure all relations will be batched, regardless of the model
      def model_relations_for_source_user_reference(model:, source_user:, user_reference_column:, alias_version:)
        aliased_model = PlaceholderReferences::AliasResolver.aliased_model(model, version: alias_version)
        aliased_user_reference_column = PlaceholderReferences::AliasResolver.aliased_column(
          model, user_reference_column, version: alias_version
        )
        primary_key = aliased_model.primary_key

        where(model:, source_user:, user_reference_column:, alias_version:).each_batch(of: MODEL_BATCH_LIMIT) do
          |placeholder_reference_batch|
          model_relation = nil

          # This is the simplest way to check for composite pkey for now. In Rails 7.1, composite primary keys will be
          # fully supported: https://guides.rubyonrails.org/7_1_release_notes.html#composite-primary-keys.
          # The `elseif primary_key.is_a?(Array)` block exists for Rails 7.1 support, so will not execute in Rails 7.0,
          # thus the code is not covered by specs and we can ignore underecoverage reports about it until we upgrade.
          # .pluck is used instead of .select to avoid CrossSchemaAccessErrors on CI tables
          # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- plucking limited by placeholder batch
          if primary_key.nil?
            composite_keys = placeholder_reference_batch.pluck(:composite_key)

            model_relation = aliased_model.where(
              "#{composite_key_columns(composite_keys)} IN #{composite_key_values(composite_keys)}"
            )
          elsif primary_key.is_a?(Array)
            composite_keys = placeholder_reference_batch.pluck(:composite_key)
            key = composite_keys.first.keys
            values = composite_keys.map(&:values)
            model_relation = aliased_model.where({ key => values })
          else
            model_relation = aliased_model.primary_key_in(placeholder_reference_batch.pluck(:numeric_key))
          end
          # rubocop: enable Database/AvoidUsingPluckWithoutLimit

          model_relation = model_relation.where(aliased_user_reference_column => source_user.placeholder_user_id)

          next if model_relation.empty?

          yield([model_relation, placeholder_reference_batch])
        end
      end

      def composite_key_columns(composite_keys)
        composite_key_columns = composite_keys.first.keys
        tuple(composite_key_columns)
      end

      def composite_key_values(composite_keys)
        keys = composite_keys.map { |composite_key| tuple(composite_key.values) }
        tuple(keys)
      end

      def tuple(values)
        "(#{values.join(', ')})"
      end
    end

    private

    def validate_numeric_or_composite_key_present
      return if numeric_key.present? ^ composite_key.present?

      errors.add(:base, :blank, message: 'one of numeric_key or composite_key must be present')
    end

    # Membership data is handled in `Import::Placeholders::Membership` records instead.
    # Use `Import::PlaceholderMemberships::CreateService` to save the membership data.
    def validate_model_is_not_member
      model_class = model&.safe_constantize
      return unless model_class.present? && model_class.new.is_a?(Member)

      errors.add(:model, :invalid, message: 'cannot be a Member')
    end
  end
end
