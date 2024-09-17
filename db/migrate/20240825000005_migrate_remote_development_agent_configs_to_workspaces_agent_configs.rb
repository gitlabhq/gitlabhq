# frozen_string_literal: true

class MigrateRemoteDevelopmentAgentConfigsToWorkspacesAgentConfigs < Gitlab::Database::Migration[2.2]
  milestone "17.4"
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  SELECTED_COLUMNS = %w[
    created_at
    updated_at
    cluster_agent_id
    enabled
    network_policy_enabled
    workspaces_quota
    workspaces_per_user_quota
    project_id
    default_max_hours_before_termination
    max_hours_before_termination_limit
    dns_zone
    gitlab_workspaces_proxy_namespace
    network_policy_egress
    default_resources_per_workspace_container
    max_resources_per_workspace
  ].join(',')

  INSERTED_VALUES = %w[
    remote_development_agent_configs.created_at
    remote_development_agent_configs.updated_at
    cluster_agent_id
    enabled
    network_policy_enabled
    workspaces_quota
    workspaces_per_user_quota
    cluster_agents.project_id
    default_max_hours_before_termination
    max_hours_before_termination_limit
    dns_zone
    gitlab_workspaces_proxy_namespace
    network_policy_egress
    default_resources_per_workspace_container
    max_resources_per_workspace
  ].join(',')

  def up
    connection.execute(<<~SQL)
      INSERT INTO workspaces_agent_configs (#{SELECTED_COLUMNS})
      SELECT #{INSERTED_VALUES}
      FROM remote_development_agent_configs
      JOIN cluster_agents ON remote_development_agent_configs.cluster_agent_id = cluster_agents.id
    SQL
  end

  def down
    connection.execute(<<~SQL)
      DELETE FROM workspaces_agent_configs
    SQL
  end
end
