# frozen_string_literal: true

class CreateAiUsageEvents < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def up
    return if table_exists?(:ai_usage_events)

    # rubocop:disable Migration/Datetime -- "timestamp" is a column name
    create_table :ai_usage_events,
      options: 'PARTITION BY RANGE (timestamp)',
      primary_key: [:id, :timestamp] do |t|
      t.bigserial :id, null: false
      t.datetime_with_timezone :timestamp, null: false
      t.belongs_to :user, null: false
      t.references :organization, foreign_key: { on_delete: :cascade }, null: false
      t.datetime_with_timezone :created_at, null: false
      t.integer :event, null: false, limit: 2
      t.jsonb :extras, default: {}, null: false
      t.belongs_to :namespace, null: true, index: false

      t.index [:namespace_id, :user_id, :event, :timestamp], unique: true, name: 'idx_ai_usage_events_unique_tuple'
    end
    # rubocop:enable Migration/Datetime
  end

  def down
    drop_table :ai_usage_events, if_exists: true, force: :cascade
  end
end
