# frozen_string_literal: true

class CreateAiDuoChatEvents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    # rubocop:disable Migration/Datetime -- "timestamp" is a column name
    create_table :ai_duo_chat_events, # rubocop:disable Migration/EnsureFactoryForTable -- code_suggestion_event
      options: 'PARTITION BY RANGE (timestamp)',
      primary_key: [:id, :timestamp] do |t|
      t.bigserial :id, null: false
      t.datetime_with_timezone :timestamp, null: false
      t.belongs_to :user, null: false
      t.references :personal_namespace, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :event, null: false, limit: 2
      t.text :namespace_path, limit: 255
      t.jsonb :payload
    end
    # rubocop:enable Migration/Datetime
  end

  def down
    drop_table :ai_duo_chat_events
  end
end
