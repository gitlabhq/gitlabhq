# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSpamLogsOrganizationId < BatchedMigrationJob
      operation_name :backfill_spam_logs_organization_id
      feature_category :instance_resiliency

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            UPDATE spam_logs
            SET organization_id = users.organization_id
            FROM users
            WHERE spam_logs.user_id = users.id
            AND spam_logs.organization_id IS NULL
            AND spam_logs.id IN (#{sub_batch.select(:id).to_sql})
          SQL
        end
      end
    end
  end
end
