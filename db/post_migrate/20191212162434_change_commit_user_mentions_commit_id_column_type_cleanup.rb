# frozen_string_literal: true

class ChangeCommitUserMentionsCommitIdColumnTypeCleanup < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  NEW_INDEX = 'commit_id_for_type_change_and_note_id_index'
  OLD_INDEX = 'commit_user_mentions_on_commit_id_and_note_id_index'

  def up
    cleanup_concurrent_column_type_change :commit_user_mentions, :commit_id
  end

  def down
    change_column_type_concurrently :commit_user_mentions, :commit_id, :binary

    # change_column_type_concurrently creates a new index based on existing commit_id_and_note_id_index` naming it
    # `commit_id_for_type_change_and_note_id_index` so we'll rename it back to its original name.
    add_concurrent_index :commit_user_mentions, [:commit_id_for_type_change, :note_id], name: OLD_INDEX
    remove_concurrent_index_by_name :commit_user_mentions, NEW_INDEX
  end
end
