# frozen_string_literal: true

class UpdateWorkspacesAgentConfigsProxyNamespaceFromEmptyHashToDefault < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  milestone '18.2'

  def up
    update_column_in_batches(
      :workspaces_agent_configs,
      :gitlab_workspaces_proxy_namespace,
      'gitlab-workspaces',
      batch_size: 500
    ) do |table, query|
      query.where(table[:gitlab_workspaces_proxy_namespace].eq('{}'))
    end
  end

  def down
    # no-op
  end
end
