# frozen_string_literal: true

class AddIndexOnAuthorIdAndIdAndCreatedAtToIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :issues, [:author_id, :id, :created_at]
  end

  def down
    remove_concurrent_index :issues, [:author_id, :id, :created_at]
  end
end
