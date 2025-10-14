# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ArchiveRevokedAccessGrants < BatchedMigrationJob
      operation_name :archive_revoked_access_grants
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          grants_to_archive = sub_batch
                                .where(revoked_at: ...cutoff_date)
                                .select(:id)
                                .limit(sub_batch_size)

          sql = <<~SQL
            WITH deleted AS (
              DELETE FROM oauth_access_grants
              WHERE id IN (#{grants_to_archive.to_sql})
              RETURNING *
            )
            INSERT INTO oauth_access_grant_archived_records
              (id, resource_owner_id, application_id, token, expires_in, redirect_uri,
               revoked_at, created_at, scopes, organization_id, code_challenge,
               code_challenge_method, archived_at)
            SELECT
              id, resource_owner_id, application_id, token, expires_in, redirect_uri,
              revoked_at, created_at, scopes, organization_id, code_challenge,
              code_challenge_method, CURRENT_TIMESTAMP as archived_at
            FROM deleted
          SQL

          archived_count = connection.execute(sql).cmd_tuples
          log_info("Processed batch - Archived: #{archived_count}")
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
