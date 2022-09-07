# frozen_string_literal: true

class DeleteNullRecordsFromBoardProjectRecentVisits < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute('DELETE FROM board_project_recent_visits WHERE user_id is null OR project_id is null OR board_id is null')
  end

  def down
    # no-op
  end
end
