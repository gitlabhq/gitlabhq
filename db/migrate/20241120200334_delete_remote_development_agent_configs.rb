# frozen_string_literal: true

class DeleteRemoteDevelopmentAgentConfigs < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone "17.7"

  TABLE_NAME = :remote_development_agent_configs

  def constraint_1_name
    check_constraint_name TABLE_NAME, :default_max_hours_before_termination, "max_size_1_year"
  end

  def constraint_2_name
    check_constraint_name TABLE_NAME, :max_hours_before_termination_limit, "max_size_1_year"
  end

  def up
    drop_table TABLE_NAME # rubocop:disable Migration/DropTable -- We have already migrated this table to workspaces_agent_configs - see https://gitlab.com/gitlab-org/gitlab/-/issues/480135
  end

  # noinspection RubyResolve -- RubyMine doesn't resolve t.bigint. TODO: Open ticket and link on https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/
  def down
    create_table TABLE_NAME do |t|
      t.timestamps_with_timezone null: false
      t.bigint "cluster_agent_id", null: false
      t.bigint "workspaces_quota", default: -1, null: false
      t.bigint "workspaces_per_user_quota", default: -1, null: false
      t.bigint "project_id"
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

      t.index :cluster_agent_id, unique: true, name: "index_remote_development_agent_configs_on_unique_agent_id"
      t.index :project_id
    end

    add_concurrent_foreign_key TABLE_NAME, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key TABLE_NAME, :cluster_agents, column: :cluster_agent_id, on_delete: :cascade
    add_check_constraint TABLE_NAME, "default_max_hours_before_termination <= 8760", constraint_1_name
    add_check_constraint TABLE_NAME, "max_hours_before_termination_limit <= 8760", constraint_2_name
  end
end
