# frozen_string_literal: true

class RaiseGroupAndProjectCiVariableLimits < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    create_or_update_plan_limit('project_ci_variables', 'default', 8000)
    create_or_update_plan_limit('group_ci_variables', 'default', 30000)
  end

  def down
    create_or_update_plan_limit('project_ci_variables', 'default', 200)
    create_or_update_plan_limit('group_ci_variables', 'default', 200)
  end
end
