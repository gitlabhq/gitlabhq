# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on how to use batched background migrations

# Update below commented lines with appropriate values.

module Gitlab
  module BackgroundMigration
    class SplitMicrosoftApplicationsTable < BatchedMigrationJob
      operation_name :split_microsoft_applications_table
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          connection.execute <<~SQL
            INSERT INTO system_access_group_microsoft_applications
              (temp_source_id, group_id, enabled, tenant_xid, client_xid, login_endpoint,
                graph_endpoint, encrypted_client_secret, encrypted_client_secret_iv, created_at, updated_at)
            SELECT
                id,
                namespace_id,
                enabled,
                tenant_xid,
                client_xid,
                login_endpoint,
                graph_endpoint,
                encrypted_client_secret,
                encrypted_client_secret_iv,
                created_at,
                updated_at
            FROM
                (#{sub_batch.where.not(namespace_id: nil).to_sql}) AS sama
            ON CONFLICT DO NOTHING
          SQL
        end
      end
    end
  end
end
