# frozen_string_literal: true

class AddIndexOnAuthorIdAndCreatedAtAndIdToNotes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :notes, [:author_id, :created_at, :id]
    remove_concurrent_index :notes, [:author_id, :created_at]
  end

  def down
    add_concurrent_index :notes, [:author_id, :created_at]
    remove_concurrent_index :notes, [:author_id, :created_at, :id]
  end
end
