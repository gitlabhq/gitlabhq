# frozen_string_literal: true

class AddEnabledPoliciesIndexToPackagesCleanupPolicies < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_enabled_pkgs_cleanup_policies_on_next_run_at_project_id'

  def up
    add_concurrent_index :packages_cleanup_policies,
                         [:next_run_at, :project_id],
                         where: "keep_n_duplicated_package_files <> 'all'",
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_cleanup_policies, INDEX_NAME
  end
end
