# frozen_string_literal: true

module Import
  class SourceUserPlaceholderReference < ApplicationRecord
    include BulkInsertSafe

    self.table_name = 'import_source_user_placeholder_references'

    belongs_to :source_user, class_name: 'Import::SourceUser'
    belongs_to :namespace

    validates :model, :namespace_id, :source_user_id, :user_reference_column, presence: true
    validates :numeric_key, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
    validates :composite_key,
      json_schema: { filename: 'import_source_user_placeholder_reference_composite_key' },
      allow_nil: true
    validate :validate_numeric_or_composite_key_present

    attribute :composite_key, :ind_jsonb

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
    ].freeze

    SerializationError = Class.new(StandardError)

    def aliased_model
      Import::PlaceholderReferenceAliasResolver.aliased_model(model)
    end

    def aliased_user_reference_column
      Import::PlaceholderReferenceAliasResolver.aliased_column(model, user_reference_column)
    end

    def aliased_composite_key
      composite_key.transform_keys do |key|
        Import::PlaceholderReferenceAliasResolver.aliased_column(model, key)
      end
    end

    def to_serialized
      Gitlab::Json.dump(attributes.slice(*SERIALIZABLE_ATTRIBUTES).to_h.values)
    end

    class << self
      def from_serialized(serialized_reference)
        deserialized = Gitlab::Json.parse(serialized_reference)

        raise SerializationError if deserialized.size != SERIALIZABLE_ATTRIBUTES.size

        attributes = SERIALIZABLE_ATTRIBUTES.zip(deserialized).to_h

        new(attributes.merge(created_at: Time.zone.now))
      end
    end

    private

    def validate_numeric_or_composite_key_present
      return if numeric_key.present? ^ composite_key.present?

      errors.add(:base, :blank, message: 'numeric_key or composite_key must be present')
    end
  end
end
