# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateDelayedDeletionPeriod < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  # Before 15.1 the only way to disable delayed deletion was to set
  # the period to 0, as of 15.1 zero is no longer a valid value (1-90).
  # This migration sets the period to a valid value and disables
  # delayed deletion using the delayed_* boolean attributes.

  def up
    execute <<~SQL
      UPDATE application_settings SET
        deletion_adjourned_period = 1,
        delayed_group_deletion = 'f',
        delayed_project_removal ='f'
      WHERE deletion_adjourned_period = 0;
    SQL
  end

  def down
    # no-op
  end
end
