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
      def cells_claims_metadata(subject_type:, subject_key: nil, source_type: nil)
        self.cells_claims_subject_type = subject_type
        self.cells_claims_subject_key = subject_key || :organization_id
        self.cells_claims_source_type = source_type ||
          Gitlab::Cells::TopologyService::Claims::V1::Source::Type
            .const_get("RAILS_TABLE_#{table_name.upcase}", false)
      end

      def cells_claims_attribute(name, type:)
        self.cells_claims_attributes = cells_claims_attributes
          .merge(name => { type: type })
          .freeze
      end
    end

    private

    def cells_claims_save_changes
      transaction_record = ::Cells::TransactionRecord.current_transaction(connection)
      return unless transaction_record

      self.class.cells_claims_attributes.each do |attribute, config|
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
        transaction_record.destroy_record(
          cells_claims_metadata_for(config[:type], public_send(attribute))) # rubocop:disable GitlabSecurity/PublicSend -- developer hard coded
      end
    end

    def cells_claims_metadata_for(type, value)
      cells_claims_default_metadata.merge({
        bucket: {
          type: type,
          value: value
        }
      })
    end

    def cells_claims_default_metadata
      @cells_claims_default_metadata ||= begin
        rails_primary_key_id = read_attribute(self.class.primary_key)

        raise MissingPrimaryKeyError unless rails_primary_key_id

        {
          subject: {
            type: self.class.cells_claims_subject_type,
            id: read_attribute(self.class.cells_claims_subject_key)
          },
          source: {
            type: self.class.cells_claims_source_type,
            rails_primary_key_id: rails_primary_key_id
          }
        }
      end
    end
  end
end
