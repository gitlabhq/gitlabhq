# frozen_string_literal: true

class AddClusterAgentsToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  def up
    add_column :application_settings, :cluster_agents, :jsonb, default: {}, null: false, if_not_exists: true

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(cluster_agents) = 'object')",
      'check_application_settings_cluster_agents_is_hash'
    )
  end

  def down
    remove_column :application_settings, :cluster_agents, if_exists: true
  end
end
