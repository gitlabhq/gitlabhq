# frozen_string_literal: true

# Returns hashes of attributes suitable for passing to `.insert_all` or `update_all`
module Integrations
  module Propagation
    module BulkOperationHashes
      private

      def integration_hash(operation)
        integration
          .to_database_hash
          .merge('inherit_from_id' => integration.inherit_from_id || integration.id)
          .merge(update_timestamps(operation))
      end

      def data_fields_hash(operation)
        integration
          .data_fields
          .to_database_hash
          .merge(update_timestamps(operation))
      end

      def update_timestamps(operation)
        time_now = Time.current

        {
          'created_at' => (time_now if operation == :create),
          'updated_at' => time_now
        }.compact
      end

      def bulk_insert_new(model, items_to_insert)
        model.insert_all(
          items_to_insert,
          returning: [:id]
        ).rows.flatten
      end
    end
  end
end
