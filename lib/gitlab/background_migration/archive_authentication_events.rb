# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ArchiveAuthenticationEvents < BatchedMigrationJob
      operation_name :archive_authentication_events
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          records_to_archive = sub_batch
                                 .where(created_at: ..Time.current.beginning_of_day - 1.year)
                                 .select(:id)
                                 .limit(sub_batch_size)

          sql = <<~SQL
            WITH deleted_records AS (
                DELETE FROM authentication_events
                WHERE id IN (#{records_to_archive.to_sql})
                RETURNING *
            )
            INSERT INTO authentication_event_archived_records
              (id, created_at, user_id, result, ip_address, provider, user_name, archived_at)
            SELECT
              id, created_at, user_id, result, ip_address, provider, user_name, CURRENT_TIMESTAMP as archived_at
            FROM deleted_records
          SQL

          archived_count = connection.execute(sql).cmd_tuples
          log_info("Processed batch: archived #{archived_count} authentication events")
        end
      end

      private

      def log_info(message)
        Gitlab::BackgroundMigration::Logger.info(
          migrator: self.class.name,
          message: message
        )
      end
    end
  end
end
