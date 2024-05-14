# frozen_string_literal: true

class AddRunnerOwnerNamespaceIdColumnToCiRunningBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  enable_lock_retries!

  def up
    add_column :ci_running_builds, :runner_owner_namespace_xid, :bigint, null: true
  end

  def down
    remove_column :ci_running_builds, :runner_owner_namespace_xid, if_exists: true
  end
end
