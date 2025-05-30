# frozen_string_literal: true

class BackfillBoardUserPreferences < Gitlab::Database::Migration[2.3]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.1'

  def up
    each_batch(:board_user_preferences, of: BATCH_SIZE) do |batch|
      connection.execute(
        <<~SQL
          UPDATE
            "board_user_preferences"
          SET
            "group_id" = "boards"."group_id",
            "project_id" = "boards"."project_id"
          FROM
            "boards"
          WHERE
            "board_user_preferences"."board_id" = "boards"."id"
            AND "board_user_preferences"."id" IN (#{batch.select(:id).limit(BATCH_SIZE).to_sql})
        SQL
      )
    end
  end

  def down
    # no-op
  end
end
