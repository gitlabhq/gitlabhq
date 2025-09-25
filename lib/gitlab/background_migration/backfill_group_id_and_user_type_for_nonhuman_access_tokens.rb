# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillGroupIdAndUserTypeForNonhumanAccessTokens < BatchedMigrationJob
      operation_name :backfill_group_id_and_user_type_for_nonhuman_access_tokens
      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          records_to_process = sub_batch.select(:id).limit(sub_batch_size)
          update_service_account_access_tokens(records_to_process)
          update_resource_access_tokens(records_to_process)
        end
      end

      private

      def update_service_account_access_tokens(sub_batch)
        # provisioned_by_group_id should always be a top-level group, but in case some
        # installations have invalid data with sub-groups assigned, we find the root namespace
        # and ensure it is a Group
        connection.execute(
          <<~SQL
            UPDATE personal_access_tokens
            SET user_type=users.user_type, group_id=(CASE
                WHEN root_namespace.type = 'Group' THEN root_namespace.id
                ELSE personal_access_tokens.group_id
              END)
            FROM
              users
              LEFT JOIN user_details ON user_details.user_id=users.id
              LEFT JOIN namespaces bot_namespace ON bot_namespace.id=user_details.provisioned_by_group_id
              LEFT JOIN namespaces root_namespace ON root_namespace.id=bot_namespace.traversal_ids[1]
            WHERE
              personal_access_tokens.id IN (#{sub_batch.to_sql})
              AND personal_access_tokens.user_type IS NULL
              AND personal_access_tokens.user_id=users.id
              AND users.user_type = 13
          SQL
        )
      end

      def update_resource_access_tokens(sub_batch)
        # Postgresql uses 1-indexing for array access, not 0-indexing
        # traversal_ids are serialized with top-level group first, and lower levels in order
        connection.execute(
          <<~SQL
            UPDATE personal_access_tokens
            SET user_type=users.user_type, group_id=(CASE
                WHEN root_namespace.type = 'Group' THEN root_namespace.id
                ELSE personal_access_tokens.group_id
              END)
            FROM
              users
              LEFT JOIN user_details ON user_details.user_id=users.id
              LEFT JOIN namespaces bot_namespace ON bot_namespace.id=user_details.bot_namespace_id
              LEFT JOIN namespaces root_namespace ON root_namespace.id=bot_namespace.traversal_ids[1]
            WHERE
              personal_access_tokens.id IN (#{sub_batch.to_sql})
              AND personal_access_tokens.user_type IS NULL
              AND personal_access_tokens.user_id=users.id
              AND users.user_type = 6
          SQL
        )
      end
    end
  end
end
