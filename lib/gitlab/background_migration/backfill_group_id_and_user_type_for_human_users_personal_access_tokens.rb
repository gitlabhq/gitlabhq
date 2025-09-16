# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillGroupIdAndUserTypeForHumanUsersPersonalAccessTokens < BatchedMigrationJob
      operation_name :backfill_group_id_and_user_type_for_human_users_personal_access_tokens
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              UPDATE personal_access_tokens
              SET user_type=users.user_type, group_id=user_details.enterprise_group_id
              FROM
                users
                LEFT JOIN user_details ON user_details.user_id=users.id
              WHERE
                personal_access_tokens.id IN (#{sub_batch.select(:id).limit(sub_batch_size).to_sql})
                AND personal_access_tokens.user_type IS NULL
                AND personal_access_tokens.user_id=users.id
                AND users.user_type = 0
            SQL
          )
        end
      end
    end
  end
end
