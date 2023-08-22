# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the users table columns with their default values
    class BackfillUsersWithDefaults < BatchedMigrationJob
      operation_name :backfill_users_with_defaults
      feature_category :user_profile

      def perform
        each_sub_batch do |sub_batch|
          connection.transaction do
            sub_batch.where(project_view: nil).update_all(project_view: 2)
            sub_batch.where(hide_no_ssh_key: nil).update_all(hide_no_ssh_key: false)
            sub_batch.where(hide_no_password: nil).update_all(hide_no_password: false)
            sub_batch.where(notified_of_own_activity: nil).update_all(notified_of_own_activity: false)
          end
        end
      end
    end
  end
end
