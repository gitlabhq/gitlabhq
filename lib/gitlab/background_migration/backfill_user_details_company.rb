# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on how to use batched background migrations

# Update below commented lines with appropriate values.

module Gitlab
  module BackgroundMigration
    class BackfillUserDetailsCompany < BatchedMigrationJob
      operation_name :backfill_user_details_company
      feature_category :organization

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
           .where("organization != '' and company = ''")
           .update_all(<<~SQL)
            company = organization
          SQL
        end
      end
    end
  end
end
