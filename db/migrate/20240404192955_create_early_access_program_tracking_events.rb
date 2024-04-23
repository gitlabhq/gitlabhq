# frozen_string_literal: true

class CreateEarlyAccessProgramTrackingEvents < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.0'

  def up
    create_table :early_access_program_tracking_events do |t|
      t.belongs_to :user, null: false, foreign_key: { on_delete: :cascade }
      t.text :event_name, null: false, index: :hash, limit: 255
      t.text :event_label, index: :hash, limit: 255
      t.text :category, index: :hash, limit: 255
      t.timestamps_with_timezone null: false
    end
  end

  def down
    drop_table :early_access_program_tracking_events
  end
end
