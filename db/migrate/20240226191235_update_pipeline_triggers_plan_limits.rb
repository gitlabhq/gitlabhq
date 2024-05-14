# frozen_string_literal: true

class UpdatePipelineTriggersPlanLimits < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.com?

    create_or_update_plan_limit('pipeline_triggers', 'premium_trial', 25000)
    create_or_update_plan_limit('pipeline_triggers', 'ultimate_trial', 25000)
    create_or_update_plan_limit('pipeline_triggers', 'opensource', 25000)
  end

  def down
    return unless Gitlab.com?

    create_or_update_plan_limit('pipeline_triggers', 'premium_trial', 0)
    create_or_update_plan_limit('pipeline_triggers', 'ultimate_trial', 0)
    create_or_update_plan_limit('pipeline_triggers', 'opensource', 0)
  end
end
