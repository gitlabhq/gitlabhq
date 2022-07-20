# frozen_string_literal: true

class AddApplicationSettingsPackagesCleanupPoliciesWorkerCapacityConstraint < Gitlab::Database::Migration[2.0]
  CONSTRAINT_NAME = 'app_settings_pkg_registry_cleanup_pol_worker_capacity_gte_zero'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings,
                         'package_registry_cleanup_policies_worker_capacity >= 0',
                         CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
