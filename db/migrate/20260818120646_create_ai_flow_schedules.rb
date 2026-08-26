# frozen_string_literal: true

class CreateAiFlowSchedules < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    create_table :ai_flow_schedules do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory added with the Ai::FlowSchedule model in a follow-up MR
      t.bigint :project_id, null: false
      t.bigint :ai_flow_trigger_id, null: false
      t.datetime_with_timezone :next_run_at
      t.datetime_with_timezone :last_run_at
      t.timestamps_with_timezone null: false
      t.integer :consecutive_failure_count, null: false, default: 0, limit: 2
      t.integer :last_run_status, limit: 2
      t.boolean :active, null: false, default: true
      t.text :cron, null: false, limit: 255
      t.text :cron_timezone, null: false, limit: 255
      t.text :last_run_error, limit: 1024
      t.text :description, null: false, limit: 255

      t.index [:next_run_at, :id], where: 'active = TRUE', name: 'index_ai_flow_schedules_on_next_run_at_and_id_active'
      t.index :project_id
      t.index :ai_flow_trigger_id
    end
  end
end
