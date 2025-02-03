# frozen_string_literal: true

class BackfillShardingKeyOnBoardAssignees < Gitlab::Database::Migration[2.2]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.9'

  def up
    each_batch(:board_assignees, of: BATCH_SIZE) do |batch|
      connection.execute(
        <<~SQL
          UPDATE
            "board_assignees"
          SET
            "group_id" = "boards"."group_id",
            "project_id" = "boards"."project_id"
          FROM
            "boards"
          WHERE
            "board_assignees"."board_id" = "boards"."id"
            AND "board_assignees"."id" IN (#{batch.select(:id).to_sql})
        SQL
      )
    end
  end

  def down
    # no-op
  end
end
