# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillListsShardingKey < BatchedMigrationJob
      operation_name :set_lists_sharding_key
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              WITH sub_batch AS MATERIALIZED (#{sub_batch.select(:id, :board_id).limit(sub_batch_size).to_sql})
              UPDATE
                "lists"
              SET
                "group_id" = "boards"."group_id", "project_id" = "boards"."project_id"
              FROM
                "sub_batch"
                INNER JOIN "boards" ON "boards"."id" = "sub_batch"."board_id"
              WHERE
                "lists"."id" = "sub_batch"."id"
            SQL
          )
        end
      end
    end
  end
end
