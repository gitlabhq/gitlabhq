# frozen_string_literal: true

class SyncTmpIndexForCleanupDualShardingKeysInNotes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  INDEX_NAME = :tmp_index_notes_on_id_with_namespace_and_project
  WHERE_CLAUSE = 'namespace_id IS NOT NULL AND project_id IS NOT NULL'

  # rubocop:disable Migration/PreventIndexCreation -- exception granted in https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/652
  def up
    add_concurrent_index :notes, :id, name: INDEX_NAME, where: WHERE_CLAUSE
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end
end
