# frozen_string_literal: true

module ClickHouse
  module SyncStrategies
    class AuditEventSyncStrategy < BaseSyncStrategy
      def execute(identifier)
        @serialized_model = build_serialized_class(identifier)
        @non_serialized_model = build_non_serialized_class(identifier)

        super()
      end

      private

      def build_serialized_class(identifier)
        Class.new(ApplicationRecord) do
          self.table_name = identifier

          include EachBatch
          self.primary_key = :id

          serialize :details, Hash
        end
      end

      def build_non_serialized_class(identifier)
        Class.new(ApplicationRecord) do
          self.table_name = identifier

          include EachBatch
          self.primary_key = :id

          attr_accessor :casted_created_at
        end
      end

      def model_class
        @serialized_model
      end

      def enabled?
        super && Feature.enabled?(:sync_audit_events_to_clickhouse, type: :gitlab_com_derisk)
      end

      def transform_row(row)
        convert_to_non_serialized_model(row)
      end

      def convert_to_non_serialized_model(serialized_model)
        non_serialized_model = @non_serialized_model.new(serialized_model.attributes)
        non_serialized_model.details = serialized_model.details.to_json
        non_serialized_model
      end

      def csv_mapping
        {
          id: :id,
          author_id: :author_id,
          author_name: :author_name,
          details: :details,
          entity_id: :entity_id,
          entity_path: :entity_path,
          entity_type: :entity_type,
          ip_address: :ip_address,
          target_details: :target_details,
          target_id: :target_id,
          target_type: :target_type,
          created_at: :casted_created_at
        }
      end

      def projections
        [
          :id,
          :author_id,
          :author_name,
          :details,
          :entity_id,
          :entity_path,
          :entity_type,
          :ip_address,
          :target_details,
          :target_id,
          :target_type,
          'EXTRACT(epoch FROM created_at) AS casted_created_at'
        ]
      end

      def insert_query
        <<~SQL.squish
          INSERT INTO audit_events (#{csv_mapping.keys.join(', ')})
          SETTINGS async_insert=1, wait_for_async_insert=1 FORMAT CSV
        SQL
      end
    end
  end
end
