# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateIssueTicketsIntoTicketType < BatchedMigrationJob
      SUPPORT_BOT_USER_TYPE = 1
      TICKET_TYPE_ID = 9

      operation_name :set_ticket_type
      feature_category :service_desk

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            WITH relation AS MATERIALIZED (
              #{sub_batch.select(:id, :author_id).limit(sub_batch_size).to_sql}
            ), filtered_relation AS MATERIALIZED (
              SELECT "relation"."id" FROM "relation"
              JOIN "users" ON "users"."id" = "relation"."author_id"
              WHERE "users"."user_type" = #{SUPPORT_BOT_USER_TYPE}
              LIMIT #{sub_batch_size}
            )
            UPDATE "issues" SET "work_item_type_id" = #{TICKET_TYPE_ID}
            FROM "filtered_relation"
            WHERE "filtered_relation"."id" = "issues"."id"
          SQL
        end
      end
    end
  end
end
