# frozen_string_literal: true

class AddDependencyFirewallPreventedPackagesProjectFk < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :dependency_firewall_prevented_packages, :projects,
      column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :dependency_firewall_prevented_packages, column: :project_id
    end
  end
end
