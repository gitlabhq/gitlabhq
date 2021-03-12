# frozen_string_literal: true

class CreateDoraDailyMetrics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :dora_daily_metrics, if_not_exists: true do |t|
        t.references :environment, null: false, foreign_key: { on_delete: :cascade }, index: false
        t.date :date, null: false
        t.integer :deployment_frequency
        t.integer :lead_time_for_changes_in_seconds

        t.index [:environment_id, :date], unique: true
      end
    end

    add_check_constraint :dora_daily_metrics, "deployment_frequency >= 0", 'dora_daily_metrics_deployment_frequency_positive'
    add_check_constraint :dora_daily_metrics, "lead_time_for_changes_in_seconds >= 0", 'dora_daily_metrics_lead_time_for_changes_in_seconds_positive'
  end

  def down
    with_lock_retries do
      drop_table :dora_daily_metrics
    end
  end
end
