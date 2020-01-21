# frozen_string_literal: true

class UpdateProjectHooksLimit < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless Gitlab.com?

    create_or_update_plan_limit('project_hooks', 'free', 100)
    create_or_update_plan_limit('project_hooks', 'bronze', 100)
    create_or_update_plan_limit('project_hooks', 'silver', 100)
  end

  def down
    return unless Gitlab.com?

    create_or_update_plan_limit('project_hooks', 'free', 10)
    create_or_update_plan_limit('project_hooks', 'bronze', 20)
    create_or_update_plan_limit('project_hooks', 'silver', 30)
  end
end
