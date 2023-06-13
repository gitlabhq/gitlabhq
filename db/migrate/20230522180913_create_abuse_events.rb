# frozen_string_literal: true

class CreateAbuseEvents < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_abuse_events_on_category_and_source'

  enable_lock_retries!

  def up
    create_table :abuse_events do |t|
      t.bigint :user_id, null: true, index: true
      t.timestamps_with_timezone null: false
      t.references :abuse_report, foreign_key: true, on_delete: :nullify, null: true, index: true
      t.integer :source, null: false, limit: 2
      t.integer :category, null: true, limit: 2
      t.jsonb :metadata, null: true
    end

    add_index :abuse_events, [:category, :source], name: INDEX_NAME
  end

  def down
    drop_table :abuse_events
  end
end
