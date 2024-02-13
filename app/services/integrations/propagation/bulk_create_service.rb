# frozen_string_literal: true

module Integrations
  module Propagation
    class BulkCreateService
      include BulkOperationHashes

      def initialize(integration, batch, association)
        @integration = integration
        @batch = batch
        @association = association
      end

      def execute
        Integration.transaction do
          inserted_ids = bulk_insert_integrations

          bulk_insert_data_fields(inserted_ids) if integration.data_fields_present?
        end
      end

      private

      attr_reader :integration, :batch, :association

      def bulk_insert_new(model, items_to_insert)
        model.insert_all(
          items_to_insert,
          returning: [:id]
        ).rows.flatten
      end

      def bulk_insert_integrations
        attributes = integration_hash(:create)

        items_to_insert = batch.select(:id).map do |record|
          attributes.merge("#{association}_id" => record.id)
        end

        bulk_insert_new(Integration, items_to_insert)
      end

      def bulk_insert_data_fields(integration_ids)
        model = integration.data_fields.class
        integration_fk_name = model.reflections['integration'].foreign_key
        attributes = data_fields_hash(:create)

        items_to_insert = integration_ids.map do |id|
          attributes.merge(integration_fk_name => id)
        end

        bulk_insert_new(model, items_to_insert)
      end
    end
  end
end
