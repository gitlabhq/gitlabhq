# frozen_string_literal: true

class AddAppSettingsDepProxyTtlWorkerCapacityCheckConstraint < Gitlab::Database::Migration[1.0]
  CONSTRAINT_NAME = 'app_settings_dep_proxy_ttl_policies_worker_capacity_positive'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'dependency_proxy_ttl_group_policy_worker_capacity >= 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
