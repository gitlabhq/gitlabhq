# frozen_string_literal: true

class AddIndexRunningBuildsOnRunnerTypeAndOwnerNamespaceIdAndId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'

  INDEX_NAME = 'idx_ci_running_builds_on_runner_type_and_owner_xid_and_id'

  def up
    add_concurrent_index(:ci_running_builds, [:runner_type, :runner_owner_namespace_xid, :runner_id], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name :ci_running_builds, INDEX_NAME, if_exists: true
  end
end
