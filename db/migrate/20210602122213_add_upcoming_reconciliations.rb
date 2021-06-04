# frozen_string_literal: true

class AddUpcomingReconciliations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      create_table :upcoming_reconciliations do |t|
        t.references :namespace, index: { unique: true }, null: true, foreign_key: { on_delete: :cascade }
        t.date :next_reconciliation_date, null: false
        t.date :display_alert_from, null: false

        t.timestamps_with_timezone
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :upcoming_reconciliations
    end
  end
end
