# frozen_string_literal: true

class AddIndexOnAuthorIdAndCreatedAtToEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :events, [:author_id, :created_at]
  end

  def down
    remove_concurrent_index :events, [:author_id, :created_at]
  end
end
