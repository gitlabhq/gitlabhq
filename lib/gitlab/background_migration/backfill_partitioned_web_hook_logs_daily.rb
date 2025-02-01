# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPartitionedWebHookLogsDaily < BatchedMigrationJob
      cursor :id, :created_at
      operation_name :update_all
      feature_category :integrations

      PARTITION_RANGE_CONDITION_REGEX = /'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})'/

      # rubocop:disable Metrics/BlockLength -- raw SQL is more readable for this migration
      # rubocop:disable Metrics/MethodLength -- raw SQL is more readable for this migration
      def perform
        each_sub_batch do |relation|
          connection.execute(<<~SQL)
            INSERT INTO web_hook_logs_daily (
              web_hook_id,
              trigger,
              url,
              request_headers,
              request_data,
              response_headers,
              response_body,
              response_status,
              execution_duration,
              internal_error_message,
              url_hash,
              created_at,
              updated_at
            )
            SELECT
              source.web_hook_id,
              source.trigger,
              source.url,
              source.request_headers,
              source.request_data,
              source.response_headers,
              source.response_body,
              source.response_status,
              source.execution_duration,
              source.internal_error_message,
              source.url_hash,
              source.created_at,
              source.updated_at
            FROM web_hook_logs AS source
            WHERE id IN (#{relation.select(:id).to_sql})
            AND created_at >= #{connection.quote(partition_lower_range)} -- Insert data in an existing partition
            ON CONFLICT (id, created_at) DO NOTHING
          SQL
        end
      end
      # rubocop:enable Metrics/BlockLength
      # rubocop:enable Metrics/MethodLength

      private

      def first_partition
        Gitlab::Database::PostgresPartitionedTable
          .find_by_name_in_current_schema('web_hook_logs_daily')
          .postgres_partitions
          .order(identifier: :asc)
          .first
      end

      def partition_lower_range
        first_partition.condition.match(PARTITION_RANGE_CONDITION_REGEX)[1]
      end
    end
  end
end
