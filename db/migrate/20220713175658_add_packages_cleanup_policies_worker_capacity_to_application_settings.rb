# frozen_string_literal: true

class AddPackagesCleanupPoliciesWorkerCapacityToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings,
               :package_registry_cleanup_policies_worker_capacity,
               :integer,
               default: 2,
               null: false
  end
end
