# frozen_string_literal: true
class AddIndexOnAuthorIdAndCreatedAtToTodos < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :todos, [:author_id, :created_at]
  end

  def down
    remove_concurrent_index :todos, [:author_id, :created_at]
  end
end
