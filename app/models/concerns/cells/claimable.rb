# frozen_string_literal: true

module Cells
  module Claimable
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    CLAIMS_BUCKET_TYPE = Gitlab::Cells::TopologyService::Claims::V1::Bucket::Type
    CLAIMS_SUBJECT_TYPE = Gitlab::Cells::TopologyService::Claims::V1::Subject::Type
    CLAIMS_SOURCE_TYPE = Gitlab::Cells::TopologyService::Claims::V1::Source::Type

    MissingPrimaryKeyError = Class.new(RuntimeError)

    included do
      after_save :cells_claims_save_changes
      before_destroy :cells_claims_destroy_changes

      class_attribute :cells_claims_subject_type, instance_accessor: false
      class_attribute :cells_claims_subject_key, instance_accessor: false
      class_attribute :cells_claims_source_type, instance_accessor: false
      class_attribute :cells_claims_attributes, instance_accessor: false, default: {}.freeze
      class_attribute :_cells_claims_scope_block, instance_accessor: false
    end

    class_methods do
      def cells_claims_metadata(subject_type:, subject_key:, source_type: nil)
        self.cells_claims_subject_type = subject_type
        self.cells_claims_subject_key = subject_key
        self.cells_claims_source_type = source_type ||
          Gitlab::Cells::TopologyService::Claims::V1::Source::Type
            .const_get("RAILS_TABLE_#{table_name.upcase}", false)
      end

      def cells_claims_scope(&block)
        if block
          self._cells_claims_scope_block = block
          return
        end

        if _cells_claims_scope_block
          instance_exec(&_cells_claims_scope_block)
        else
          all
        end
      end

      def cells_claims_attribute(name, type:, feature_flag: nil, **options)
        if options.key?(:if) && !options[:if].nil? && !options[:if].is_a?(Proc)
          raise ArgumentError,
            "cells_claims_attribute :#{name} `if:` must be a Proc/lambda or nil, got: #{options[:if].class}"
        end

        self.cells_claims_attributes = cells_claims_attributes
          .merge(name => { type: type, feature_flag: feature_flag, if: options[:if] })
          .freeze

        register_as_model_with_claims
      end

      # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- need to check against feature flag name dynamically
      def cells_claims_enabled_for_attribute?(attribute_config)
        return true if attribute_config[:feature_flag].nil?

        Feature.enabled?(attribute_config[:feature_flag], :current_request)
      end
      # rubocop:enable Gitlab/FeatureFlagKeyDynamic
    end

    mattr_reader :models_with_claims, default: Set.new

    def handle_grpc_error(error)
      case error.code
      when GRPC::Core::StatusCodes::ALREADY_EXISTS
        unique_attribute = unique_attributes.to_sentence(two_words_connector: ' or ')
        error_key = :"#{unique_attribute.parameterize(separator: '_')}_taken"
        return if errors.added?(:base, error_key)

        errors.add(:base, error_key, message: "#{unique_attribute} has already been taken")
      when GRPC::Core::StatusCodes::DEADLINE_EXCEEDED
        errors.add(:base, "Request timed out. Please try again.")
      when GRPC::Core::StatusCodes::NOT_FOUND
        errors.add(:base, "The requested resource does not exist.")
      else
        errors.add(:base, "An error occurred while processing your request")
      end
    end

    # Returns an array of metadata for all claim attributes
    def cells_claims_metadata
      self.class.cells_claims_attributes.filter_map do |attribute, config|
        next unless cells_claims_attribute_claimable?(config)

        cells_claims_metadata_for(config[:type], self[attribute])
      end
    end

    # Returns the claim metadata for a specific attribute, or nil if not claimable
    def cells_claims_metadata_for_attribute(attr_name)
      config = self.class.cells_claims_attributes[attr_name]
      return unless config
      return unless cells_claims_attribute_claimable?(config)

      cells_claims_metadata_for(config[:type], self[attr_name])
    end

    private

    class_methods do
      def register_as_model_with_claims
        Claimable.models_with_claims.add(self)
      end
    end

    def cells_claims_attribute_claimable?(config)
      return true unless config[:if]

      config[:if].call(self)
    end

    def cells_claims_save_changes
      transaction_record = ::Cells::TransactionRecord.current_transaction(connection)
      return unless transaction_record

      self.class.cells_claims_attributes.each do |attribute, config|
        next unless self.class.cells_claims_enabled_for_attribute?(config)
        next unless saved_change_to_attribute?(attribute)

        was, is = saved_change_to_attribute(attribute)

        if was && was != is
          transaction_record.destroy_record(
            cells_claims_metadata_for(config[:type], was))
        end

        if is && cells_claims_attribute_claimable?(config)
          transaction_record.create_record(
            cells_claims_metadata_for(config[:type], public_send(attribute))) # rubocop:disable GitlabSecurity/PublicSend -- developer hard coded
        end
      end
    end

    def cells_claims_destroy_changes
      transaction_record = ::Cells::TransactionRecord.current_transaction(connection)
      return unless transaction_record

      self.class.cells_claims_attributes.each do |attribute, config|
        next unless self.class.cells_claims_enabled_for_attribute?(config)

        transaction_record.destroy_record(
          cells_claims_metadata_for(config[:type], public_send(attribute))) # rubocop:disable GitlabSecurity/PublicSend -- developer hard coded
      end
    end

    def cells_claims_metadata_for(type, value)
      cells_claims_default_metadata.merge({
        bucket: {
          type: type,
          value: value.to_s
        }
      })
    end

    def cells_claims_default_metadata
      rails_primary_key = read_attribute(self.class.primary_key)

      raise MissingPrimaryKeyError unless rails_primary_key

      {
        subject: {
          type: self.class.cells_claims_subject_type,
          id: cells_claims_subject_key
        },
        source: {
          type: self.class.cells_claims_source_type,
          rails_primary_key_id: Serialization.to_bytes(rails_primary_key)
        },
        record: self
      }
    end
    strong_memoize_attr :cells_claims_default_metadata

    def cells_claims_subject_key
      subject_key = self.class.cells_claims_subject_key

      case subject_key
      when Symbol
        read_attribute(subject_key)
      when Proc
        instance_exec(&subject_key)
      else
        raise ArgumentError, "subject_key must be a Symbol or a Proc, but got: #{subject_key.class}"
      end
    end
  end
end
