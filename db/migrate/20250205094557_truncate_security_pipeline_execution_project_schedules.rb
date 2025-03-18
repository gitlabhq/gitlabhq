# frozen_string_literal: true

class TruncateSecurityPipelineExecutionProjectSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    truncate_tables!('security_pipeline_execution_project_schedules')
  end

  def down
    # no-op
  end
end
