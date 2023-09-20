# frozen_string_literal: true

class RemovePagesDeploymentsProjectIdPathPrefixUniqueIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :pages_deployments,
      'index_pages_deployments_unique_path_prefix_by_project'
  end

  def down
    # no op
  end
end
