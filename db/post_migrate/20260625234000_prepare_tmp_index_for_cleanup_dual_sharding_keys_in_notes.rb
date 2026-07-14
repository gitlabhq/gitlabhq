# frozen_string_literal: true

class PrepareTmpIndexForCleanupDualShardingKeysInNotes < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  INDEX_NAME = :tmp_index_notes_on_id_with_namespace_and_project
  WHERE_CLAUSE = 'namespace_id IS NOT NULL AND project_id IS NOT NULL'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- temp index that accelerates the CleanupDualShardingKeysInNotes BBM scan, requested in database review on https://gitlab.com/gitlab-org/gitlab/-/merge_requests/238033 -- database-team exception: https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/652
    prepare_async_index :notes, :id, name: INDEX_NAME, where: WHERE_CLAUSE
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index_by_name :notes, INDEX_NAME
  end
end
