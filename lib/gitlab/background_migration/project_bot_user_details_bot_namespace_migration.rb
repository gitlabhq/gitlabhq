# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ProjectBotUserDetailsBotNamespaceMigration < BatchedMigrationJob
      operation_name :backfill_bot_namespace_id
      scope_to ->(relation) do
        relation.where(user_type: 6)
      end

      feature_category :system_access

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              WITH user_namespaces AS (
                  SELECT
                      DISTINCT ON (u.id)
                      u.id AS user_id,
                      m.member_namespace_id AS namespace_id
                  FROM
                      users AS u
                      LEFT JOIN members AS m ON m.user_id = u.id
                      LEFT JOIN user_details AS ud ON ud.user_id = u.id
                  WHERE
                    ud.bot_namespace_id IS NULL
                    AND u.id IN (#{sub_batch.select(:id).to_sql})
              )
              UPDATE user_details AS ud
              SET
                  bot_namespace_id = un.namespace_id
              FROM
                  user_namespaces AS un
              WHERE
                  ud.user_id = un.user_id
            SQL
          )
        end
      end
    end
  end
end
