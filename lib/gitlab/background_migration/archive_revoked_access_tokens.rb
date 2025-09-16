# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ArchiveRevokedAccessTokens < BatchedMigrationJob
      operation_name :archive_revoked_access_tokens
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          tokens_to_archive = sub_batch
                                .where(revoked_at: ...cutoff_date)
                                .select(:id)
                                .limit(sub_batch_size)

          sql = <<~SQL
              WITH deleted AS (
                DELETE FROM oauth_access_tokens
                WHERE id IN (#{tokens_to_archive.to_sql})
              RETURNING *
            )
            INSERT INTO oauth_access_token_archived_records
              (id, resource_owner_id, application_id, token, refresh_token,
               expires_in, revoked_at, created_at, scopes, organization_id, archived_at)
            SELECT
              id, resource_owner_id, application_id, token, refresh_token,
              expires_in, revoked_at, created_at, scopes, organization_id,
              CURRENT_TIMESTAMP as archived_at
            FROM deleted
          SQL

          archived_count = connection.execute(sql).cmd_tuples
          log_info("Processed batch: archived #{archived_count} tokens")
        end
      end

      private

      def cutoff_date
        1.month.ago.beginning_of_day
      end

      def log_info(message)
        Gitlab::BackgroundMigration::Logger.info(
          migrator: self.class.name,
          message: message
        )
      end
    end
  end
end
