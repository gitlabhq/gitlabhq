# frozen_string_literal: true

class InsertRunnerRegistrationPlanLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    create_or_update_plan_limit('ci_registered_group_runners', 'free', 50)
    create_or_update_plan_limit('ci_registered_group_runners', 'bronze', 1000)
    create_or_update_plan_limit('ci_registered_group_runners', 'silver', 1000)
    create_or_update_plan_limit('ci_registered_group_runners', 'gold', 1000)

    create_or_update_plan_limit('ci_registered_project_runners', 'free', 50)
    create_or_update_plan_limit('ci_registered_project_runners', 'bronze', 1000)
    create_or_update_plan_limit('ci_registered_project_runners', 'silver', 1000)
    create_or_update_plan_limit('ci_registered_project_runners', 'gold', 1000)
  end

  def down
    %w[group project].each do |scope|
      create_or_update_plan_limit("ci_registered_#{scope}_runners", 'free', 1000)
      create_or_update_plan_limit("ci_registered_#{scope}_runners", 'bronze', 1000)
      create_or_update_plan_limit("ci_registered_#{scope}_runners", 'silver', 1000)
      create_or_update_plan_limit("ci_registered_#{scope}_runners", 'gold', 1000)
    end
  end
end
