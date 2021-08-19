# frozen_string_literal: true

class AddUniqueCommitDesignUserMentionIndexes < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  COMMIT_INDEX_NAME = 'commit_id_and_note_id_index'
  DESIGN_INDEX_NAME = 'design_user_mentions_on_design_id_and_note_id_index'

  COMMIT_UNIQUE_INDEX_NAME = 'commit_user_mentions_on_commit_id_and_note_id_unique_index'
  DESIGN_UNIQUE_INDEX_NAME = 'design_user_mentions_on_design_id_and_note_id_unique_index'

  def up
    add_concurrent_index :commit_user_mentions, [:commit_id, :note_id], unique: true, name: COMMIT_UNIQUE_INDEX_NAME
    add_concurrent_index :design_user_mentions, [:design_id, :note_id], unique: true, name: DESIGN_UNIQUE_INDEX_NAME

    remove_concurrent_index_by_name :commit_user_mentions, COMMIT_INDEX_NAME
    remove_concurrent_index_by_name :design_user_mentions, DESIGN_INDEX_NAME
  end

  def down
    add_concurrent_index :design_user_mentions, [:design_id, :note_id], name: DESIGN_INDEX_NAME
    add_concurrent_index :commit_user_mentions, [:commit_id, :note_id], name: COMMIT_INDEX_NAME

    remove_concurrent_index_by_name :design_user_mentions, DESIGN_UNIQUE_INDEX_NAME
    remove_concurrent_index_by_name :commit_user_mentions, COMMIT_UNIQUE_INDEX_NAME
  end
end
