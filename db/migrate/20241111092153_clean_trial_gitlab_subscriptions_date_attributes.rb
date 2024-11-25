# frozen_string_literal: true

class CleanTrialGitlabSubscriptionsDateAttributes < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.7'

  def up
    execute <<~SQL
      UPDATE gitlab_subscriptions
        SET
          trial_starts_on = COALESCE(trial_starts_on, start_date),
          trial_ends_on = COALESCE(trial_ends_on, end_date)
        WHERE trial = true
          AND (trial_starts_on IS NULL OR trial_ends_on IS NULL)
    SQL

    execute <<~SQL
      UPDATE gitlab_subscriptions
        SET
          trial_ends_on = trial_ends_on + 1,
          end_date = end_date + 1
        WHERE trial = true
          AND trial_starts_on = trial_ends_on
    SQL
  end

  def down
    # This migration is not possible to be reverted
  end
end
