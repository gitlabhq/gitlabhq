# frozen_string_literal: true

class AddApplicationSettingsPackageFilesLimitConstraints < Gitlab::Database::Migration[1.0]
  CONSTRAINT_NAME = 'app_settings_max_package_files_for_package_destruction_positive'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'max_package_files_for_package_destruction > 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
