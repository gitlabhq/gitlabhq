# frozen_string_literal: true

class AddPackagesCleanupPackageFileWorkerCapacityCheckConstraintToAppSettings < Gitlab::Database::Migration[1.0]
  CONSTRAINT_NAME = 'app_settings_p_cleanup_package_file_worker_capacity_positive'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'packages_cleanup_package_file_worker_capacity >= 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
