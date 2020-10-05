# frozen_string_literal: true

class AddPostgresReindexActionsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :postgres_reindex_actions, if_not_exists: true do |t|
      t.datetime_with_timezone :action_start, null: false
      t.datetime_with_timezone :action_end
      t.bigint :ondisk_size_bytes_start, null: false
      t.bigint :ondisk_size_bytes_end
      t.integer :state, limit: 2, null: false, default: 0
      t.text :index_identifier, null: false, index: true
    end

    add_text_limit(:postgres_reindex_actions, :index_identifier, 255)
  end

  def down
    drop_table :postgres_reindex_actions
  end
end
