# frozen_string_literal: true

class UnlockDelayedProjectRemoval < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  # As part of https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86568 the
  # lock_delayed_project_removal setting is updated for the first time. No up
  # migration is needed because the column existsted. However a down migration
  # is needed to disable the settting because users would have no way to edit it
  # and would have the cascading setting permanently locked on groups.

  def up
    # no-op
  end

  def down
    ApplicationSetting.reset_column_information

    ApplicationSetting.update_all(lock_delayed_project_removal: false)
  end
end
