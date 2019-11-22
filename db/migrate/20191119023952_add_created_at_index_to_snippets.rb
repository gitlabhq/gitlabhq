# frozen_string_literal: true

class AddCreatedAtIndexToSnippets < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :snippets, :created_at
  end

  def down
    remove_concurrent_index :snippets, :created_at
  end
end
