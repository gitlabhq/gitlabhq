# frozen_string_literal: true

class BackfillShardingKeyOnBoardLabels < Gitlab::Database::Migration[2.2]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.9'

  def up
    each_batch(:board_labels, of: BATCH_SIZE) do |batch|
      connection.execute(
        <<~SQL
          UPDATE
            "board_labels"
          SET
            "group_id" = "boards"."group_id",
            "project_id" = "boards"."project_id"
          FROM
            "boards"
          WHERE
            "board_labels"."board_id" = "boards"."id"
            AND "board_labels"."id" IN (#{batch.select(:id).limit(BATCH_SIZE).to_sql})
        SQL
      )
    end
  end

  def down
    # no-op
  end
end
