# frozen_string_literal: true

class ChangeCommitUserMentionsCommitIdColumnType < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  OLD_INDEX = 'commit_user_mentions_on_commit_id_and_note_id_index'
  OLD_TMP_INDEX = 'temp_commit_id_and_note_id_index'
  NEW_TMP_INDEX = 'temp_commit_id_for_type_change_and_note_id_index'
  NEW_INDEX = 'commit_id_and_note_id_index'

  def up
    # the initial index name is too long and fails during migration. Renaming the index first.
    add_concurrent_index :commit_user_mentions, [:commit_id, :note_id], name: OLD_TMP_INDEX
    remove_concurrent_index_by_name :commit_user_mentions, OLD_INDEX

    change_column_type_concurrently :commit_user_mentions, :commit_id, :string

    # change_column_type_concurrently creates a new index for new column `commit_id_for_type` based on existing
    # `temp_commit_id_and_note_id_index` naming it `temp_commit_id_for_type_change_and_note_id_index`, yet keeping
    # `temp_commit_id_and_note_id_index` for `commit_id`, that will be cleaned
    # by `cleanup_concurrent_column_type_change :commit_user_mentions, :commit_id` in a later migration.
    #
    # So we'll rename `temp_commit_id_for_type_change_and_note_id_index` to initialy intended name: `commit_id_and_note_id_index`.

    add_concurrent_index :commit_user_mentions, [:commit_id_for_type_change, :note_id], name: NEW_INDEX
    remove_concurrent_index_by_name :commit_user_mentions, NEW_TMP_INDEX
  end

  def down
    cleanup_concurrent_column_type_change :commit_user_mentions, :commit_id
  end
end
