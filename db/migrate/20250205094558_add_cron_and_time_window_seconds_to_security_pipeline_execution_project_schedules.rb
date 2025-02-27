# frozen_string_literal: true

class AddCronAndTimeWindowSecondsToSecurityPipelineExecutionProjectSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  TABLE_NAME = :security_pipeline_execution_project_schedules

  def up
    with_lock_retries do
      # rubocop:disable Rails/NotNullColumn -- table was emptied by previous migration
      add_column TABLE_NAME, :time_window_seconds, :integer, null: false, if_not_exists: true
      add_column TABLE_NAME, :cron, :text, null: false, if_not_exists: true
      add_column TABLE_NAME, :cron_timezone, :text, null: false, if_not_exists: true
      # rubocop:enable Rails/NotNullColumn
    end

    add_text_limit TABLE_NAME, :cron, 128
    add_text_limit TABLE_NAME, :cron_timezone, 255

    constraint_name = check_constraint_name(TABLE_NAME, :time_window_seconds, "positive")
    add_check_constraint TABLE_NAME, "time_window_seconds > 0", constraint_name
  end

  def down
    with_lock_retries do
      remove_column TABLE_NAME, :time_window_seconds, if_exists: true
      remove_column TABLE_NAME, :cron, if_exists: true
      remove_column TABLE_NAME, :cron_timezone, if_exists: true
    end
  end
end
