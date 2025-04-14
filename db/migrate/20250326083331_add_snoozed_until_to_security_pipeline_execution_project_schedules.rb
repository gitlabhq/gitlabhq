# frozen_string_literal: true

class AddSnoozedUntilToSecurityPipelineExecutionProjectSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :security_pipeline_execution_project_schedules, :snoozed_until, :datetime_with_timezone
  end
end
