# frozen_string_literal: true

class DeleteNullRecordsFromBoardGroupRecentVisits < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute('DELETE FROM board_group_recent_visits WHERE user_id is null OR group_id is null OR board_id is null')
  end

  def down
    # no-op
  end
end
