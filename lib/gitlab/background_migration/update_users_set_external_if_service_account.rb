# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class is responsible for updating users external field if service account.
    class UpdateUsersSetExternalIfServiceAccount < BatchedMigrationJob
      operation_name :update # This is used as the key on collecting metrics
      scope_to ->(relation) { relation.where(user_type: HasUserType::USER_TYPES[:service_account]) }
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(external: true)
        end
      end
    end
  end
end
