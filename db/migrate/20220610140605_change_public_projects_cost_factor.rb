# frozen_string_literal: true

class ChangePublicProjectsCostFactor < Gitlab::Database::Migration[2.0]
  # This migration updates SaaS Runner cost factors for public projects.
  # Previously we had a disabled cost factor for public projects, meaning
  # that no CI minutes were counted by default. With a low cost factor
  # we count CI minutes consumption at a very low rate to prevent
  # abuses.
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  DISABLED_COST_FACTOR = 0
  LOW_COST_FACTOR = 0.008

  class Runner < MigrationRecord
    self.table_name = 'ci_runners'

    scope :shared, -> { where(runner_type: 1) }
  end

  def up
    return unless Gitlab.com?

    Runner.shared.where(public_projects_minutes_cost_factor: DISABLED_COST_FACTOR)
      .update_all(public_projects_minutes_cost_factor: LOW_COST_FACTOR)
  end

  def down
    return unless Gitlab.com?

    Runner.shared.where(public_projects_minutes_cost_factor: LOW_COST_FACTOR)
      .update_all(public_projects_minutes_cost_factor: DISABLED_COST_FACTOR)
  end
end
