# frozen_string_literal: true

class AddTemporaryMergeRequestWithMentionsIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_CONDITION = "description like '%@%' OR title like '%@%'"
  INDEX_NAME = 'merge_request_mentions_temp_index'

  disable_ddl_transaction!

  def up
    # create temporary index for notes with mentions, may take well over 1h
    add_concurrent_index(:merge_requests, :id, where: INDEX_CONDITION, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:merge_requests, :id, where: INDEX_CONDITION, name: INDEX_NAME)
  end
end
