# frozen_string_literal: true

class AddIndexOnAuthorIdAndCreatedAtToEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_events_on_author_id_and_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :events, [:author_id, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :events, INDEX_NAME
  end
end
