# frozen_string_literal: true

# Regular rather than post-deployment on purpose: the marker must exist before
# flag-on code serves requests, or a zero-downtime upgrade that defers
# post-deployment migrations treats beta instances as new customers meanwhile.
# Single-row UPDATE; the old code never reads the column.
class BackfillApplicationSettingsSecretsManagerInstanceBetaEnrolled < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  # Runs on every realm. Only self-managed can be instance-enrolled, and every
  # such instance enrolled while the paid experience flag was off, so enrolled
  # means beta-enrolled. On GitLab.com the source column is always false.
  def up
    ApplicationSetting.reset_column_information

    ApplicationSetting.update_all('secrets_manager_instance_beta_enrolled = secrets_manager_instance_enrolled')
  end

  def down
    # no-op: the column is dropped by the preceding migration's down
  end
end
