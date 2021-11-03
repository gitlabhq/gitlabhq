# frozen_string_literal: true

class AddReindexingQueue < Gitlab::Database::Migration[1.0]
  def change
    create_table :postgres_reindex_queued_actions do |t|
      t.text :index_identifier, null: false, limit: 255
      t.integer :state, limit: 2, null: false, default: 0
      t.timestamps_with_timezone null: false

      t.index :state
    end

    change_column_default :postgres_reindex_queued_actions, :created_at, from: nil, to: -> { 'NOW()' }
    change_column_default :postgres_reindex_queued_actions, :updated_at, from: nil, to: -> { 'NOW()' }
  end
end
