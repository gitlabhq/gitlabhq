# frozen_string_literal: true

class UpdatePipelineTriggersPremiumUltimatePlanLimits < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.com?

    create_or_update_plan_limit('pipeline_triggers', 'premium', 25000)
    create_or_update_plan_limit('pipeline_triggers', 'ultimate', 25000)
  end

  def down
    return unless Gitlab.com?

    create_or_update_plan_limit('pipeline_triggers', 'premium', 0)
    create_or_update_plan_limit('pipeline_triggers', 'ultimate', 0)
  end
end
