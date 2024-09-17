# frozen_string_literal: true

class CreateWorkspacesAgentConfigs < Gitlab::Database::Migration[2.2]
  milestone "17.4"

  # noinspection RubyResolve -- RubyMine doesn't resolve t.bigint. TODO: Open ticket and link on https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/
  def change
    create_table(:workspaces_agent_configs) do |t|
      t.timestamps_with_timezone null: false
      t.bigint "cluster_agent_id", null: false
      t.bigint "workspaces_quota", default: -1, null: false
      t.bigint "workspaces_per_user_quota", default: -1, null: false
      t.bigint "project_id", null: false
      t.column "default_max_hours_before_termination", :smallint, default: 24, null: false
      t.column "max_hours_before_termination_limit", :smallint, default: 120, null: false
      t.boolean "enabled", null: false
      t.boolean "network_policy_enabled", default: true, null: false
      t.text "dns_zone", limit: 256, null: false
      # Kubernetes namespaces are limited to 63 characters
      t.text "gitlab_workspaces_proxy_namespace", limit: 63, default: "gitlab-workspaces", null: false
      t.jsonb "network_policy_egress",
        default: [{ "allow" => "0.0.0.0/0", "except" => %w[10.0.0.0/8 172.16.0.0/12 192.168.0.0/16] }], null: false
      t.jsonb "default_resources_per_workspace_container", default: {}, null: false
      t.jsonb "max_resources_per_workspace", default: {}, null: false

      t.index :cluster_agent_id, unique: true, name: "index_workspaces_agent_configs_on_unique_cluster_agent_id"
      t.index :project_id
    end
  end
end
