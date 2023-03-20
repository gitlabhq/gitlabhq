# frozen_string_literal: true

class AddPublicRunnerReleaseVersionFetchSetting < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_column :application_settings, :update_runner_versions_enabled, :boolean,
      default: true, null: false, if_not_exists: true
  end

  def down
    remove_column :application_settings, :update_runner_versions_enabled, if_exists: true
  end
end
