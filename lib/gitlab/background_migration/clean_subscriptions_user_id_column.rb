# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CleanSubscriptionsUserIdColumn < BatchedMigrationJob
      operation_name :clean_subscriptions_user_id
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              WITH relation AS MATERIALIZED (
                #{sub_batch.limit(sub_batch_size).to_sql}
              ), filtered_relation AS MATERIALIZED (
                SELECT "id" from relation WHERE
                  NOT EXISTS (SELECT 1 FROM "users" WHERE "users"."id" = relation."user_id")
                  LIMIT #{sub_batch_size}
              )
              DELETE FROM "subscriptions" WHERE "id" IN (SELECT "id" FROM filtered_relation)
            SQL
          )
        end
      end
    end
  end
end
