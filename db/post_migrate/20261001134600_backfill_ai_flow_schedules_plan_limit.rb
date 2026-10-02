# frozen_string_literal: true

class BackfillAiFlowSchedulesPlanLimit < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '19.5'

  OLD_LIMIT = 10
  NEW_LIMIT = 100

  def up
    execute("UPDATE plan_limits SET ai_flow_schedules = #{NEW_LIMIT} WHERE ai_flow_schedules = #{OLD_LIMIT}")
  end

  def down
    execute("UPDATE plan_limits SET ai_flow_schedules = #{OLD_LIMIT} WHERE ai_flow_schedules = #{NEW_LIMIT}")
  end
end
