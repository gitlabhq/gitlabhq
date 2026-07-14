# frozen_string_literal: true

class AddDependencyFirewallActivityStatsProjectFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  def up
    add_concurrent_foreign_key :dependency_firewall_activity_stats, :projects,
      column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :dependency_firewall_activity_stats, column: :project_id
    end
  end
end
