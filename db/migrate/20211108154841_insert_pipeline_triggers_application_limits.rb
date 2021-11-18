# frozen_string_literal: true

class InsertPipelineTriggersApplicationLimits < Gitlab::Database::Migration[1.0]
  def up
    create_or_update_plan_limit('pipeline_triggers', 'default', 0)
    create_or_update_plan_limit('pipeline_triggers', 'free', 25_000)
    create_or_update_plan_limit('pipeline_triggers', 'opensource', 0)
    create_or_update_plan_limit('pipeline_triggers', 'premium', 0)
    create_or_update_plan_limit('pipeline_triggers', 'premium_trial', 0)
    create_or_update_plan_limit('pipeline_triggers', 'ultimate', 0)
    create_or_update_plan_limit('pipeline_triggers', 'ultimate_trial', 0)
  end

  def down
    create_or_update_plan_limit('pipeline_triggers', 'default', 0)
    create_or_update_plan_limit('pipeline_triggers', 'free', 0)
    create_or_update_plan_limit('pipeline_triggers', 'opensource', 0)
    create_or_update_plan_limit('pipeline_triggers', 'premium', 0)
    create_or_update_plan_limit('pipeline_triggers', 'premium_trial', 0)
    create_or_update_plan_limit('pipeline_triggers', 'ultimate', 0)
    create_or_update_plan_limit('pipeline_triggers', 'ultimate_trial', 0)
  end
end
