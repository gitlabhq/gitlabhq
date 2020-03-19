# frozen_string_literal: true

class AddIndexOnAuthorIdAndIdAndCreatedAtToNotes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :notes, [:author_id, :created_at]
    remove_concurrent_index :notes, [:author_id]
  end

  def down
    add_concurrent_index :notes, [:author_id]
    remove_concurrent_index :notes, [:author_id, :created_at]
  end
end
