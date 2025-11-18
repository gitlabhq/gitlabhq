# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RemoveRowsWithDeletedUserFromIdentities < BatchedMigrationJob
      operation_name :remove_rows_with_deleted_user_from_identities
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .joins('LEFT OUTER JOIN users ON identities.user_id = users.id')
            .where(users: { id: nil })
            .delete_all
        end
      end
    end
  end
end
