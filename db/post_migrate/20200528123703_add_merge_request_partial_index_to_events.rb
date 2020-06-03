# frozen_string_literal: true

class AddMergeRequestPartialIndexToEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_events_on_author_id_and_created_at_merge_requests'

  def up
    add_concurrent_index(
      :events,
      [:author_id, :created_at],
      name: INDEX_NAME,
      where: "(target_type = 'MergeRequest')"
    )
  end

  def down
    remove_concurrent_index :events, INDEX_NAME
  end
end
