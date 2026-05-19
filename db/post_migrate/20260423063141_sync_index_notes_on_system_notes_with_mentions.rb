# frozen_string_literal: true

class SyncIndexNotesOnSystemNotesWithMentions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  INDEX_NAME = 'index_notes_on_system_notes_with_mentions'

  # rubocop:disable Migration/PreventIndexCreation -- exception granted in https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/606
  def up
    add_concurrent_index :notes, [:noteable_id, :noteable_type], name: INDEX_NAME,
      where: "system = TRUE AND note LIKE '%@%'"
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end
end
