# frozen_string_literal: true

class AddContinuousVulnScansToggleToSecurityProjectSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!
  TABLE_NAME = :project_security_settings
  COLUMN_NAME = :continuous_vulnerability_scans_enabled

  def up
    add_column TABLE_NAME, COLUMN_NAME, :boolean, null: false,
      default: false
  end

  def down
    remove_column TABLE_NAME, COLUMN_NAME
  end
end
