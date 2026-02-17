# frozen_string_literal: true

module Cells
  module Claimable
    extend ActiveSupport::Concern

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
    end

    class_methods do
      def cells_claims_metadata(subject_type:, subject_key:, source_type: nil)
        self.cells_claims_subject_type = subject_type
        self.cells_claims_subject_key = subject_key
        self.cells_claims_source_type = source_type ||
          Gitlab::Cells::TopologyService::Claims::V1::Source::Type
            .const_get("RAILS_TABLE_#{table_name.upcase}", false)
      end

      def cells_claims_attribute(name, type:, feature_flag: nil)
        self.cells_claims_attributes = cells_claims_attributes
          .merge(name => { type: type, feature_flag: feature_flag })
          .freeze
      end
    end

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

    private

    # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- need to check against feature flag name dynamically
    def cells_claims_enabled_for_attribute?(attribute_config)
      return true if attribute_config[:feature_flag].nil?

      Feature.enabled?(attribute_config[:feature_flag], :current_request)
    end
    # rubocop:enable Gitlab/FeatureFlagKeyDynamic

    def cells_claims_save_changes
      transaction_record = ::Cells::TransactionRecord.current_transaction(connection)
      return unless transaction_record

      self.class.cells_claims_attributes.each do |attribute, config|
        next unless cells_claims_enabled_for_attribute?(config)
        next unless saved_change_to_attribute?(attribute)

        was, is = saved_change_to_attribute(attribute)

        if was && was != is
          transaction_record.destroy_record(
            cells_claims_metadata_for(config[:type], was))
        end

        if is
          transaction_record.create_record(
            cells_claims_metadata_for(config[:type], public_send(attribute))) # rubocop:disable GitlabSecurity/PublicSend -- developer hard coded
        end
      end
    end

    def cells_claims_destroy_changes
      transaction_record = ::Cells::TransactionRecord.current_transaction(connection)
      return unless transaction_record

      self.class.cells_claims_attributes.each do |attribute, config|
        next unless cells_claims_enabled_for_attribute?(config)

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
      @cells_claims_default_metadata ||= begin
        rails_primary_key = read_attribute(self.class.primary_key)

        raise MissingPrimaryKeyError unless rails_primary_key

        rails_primary_key_bytes =
          case rails_primary_key
          when Integer
            [rails_primary_key].pack("Q>") # uint64 big-endian
          when String
            if Gitlab::UUID.uuid?(rails_primary_key)
              [rails_primary_key.delete("-")].pack("H*") # UUID: remove dashes and encode as hex
            else
              rails_primary_key # Raw string, pass as is
            end
          else
            raise ArgumentError, "Unsupported primary key type: #{rails_primary_key.class}"
          end

        {
          subject: {
            type: self.class.cells_claims_subject_type,
            id: cells_claims_subject_key
          },
          source: {
            type: self.class.cells_claims_source_type,
            rails_primary_key_id: rails_primary_key_bytes
          },
          record: self
        }
      end
    end

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
