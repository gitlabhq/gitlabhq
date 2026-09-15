# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillEmailsOrganizationId < BatchedMigrationJob
      operation_name :backfill_emails_organization_id
      feature_category :user_profile

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            UPDATE emails
            SET organization_id = users.organization_id
            FROM users
            WHERE emails.user_id = users.id
              AND emails.organization_id IS NULL
              AND emails.id IN (#{sub_batch.select(:id).to_sql})
          SQL
        end
      end
    end
  end
end
