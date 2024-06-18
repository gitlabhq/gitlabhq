# frozen_string_literal: true

class CleanupRunnerNamespacesWithNullNamespaceId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  milestone '17.1'

  class CiRunnerNamespace < MigrationRecord
    self.table_name = 'ci_runner_namespaces'
  end

  def up
    CiRunnerNamespace.where(namespace_id: nil).delete_all
  end

  def down
    # no-op : can't recover deleted records
  end
end
