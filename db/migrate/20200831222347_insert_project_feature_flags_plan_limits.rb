# frozen_string_literal: true

class InsertProjectFeatureFlagsPlanLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless Gitlab.com?

    create_or_update_plan_limit('project_feature_flags', 'free', 50)
    create_or_update_plan_limit('project_feature_flags', 'bronze', 100)
    create_or_update_plan_limit('project_feature_flags', 'silver', 150)
    create_or_update_plan_limit('project_feature_flags', 'gold', 200)
  end

  def down
    return unless Gitlab.com?

    create_or_update_plan_limit('project_feature_flags', 'free', 0)
    create_or_update_plan_limit('project_feature_flags', 'bronze', 0)
    create_or_update_plan_limit('project_feature_flags', 'silver', 0)
    create_or_update_plan_limit('project_feature_flags', 'gold', 0)
  end
end
