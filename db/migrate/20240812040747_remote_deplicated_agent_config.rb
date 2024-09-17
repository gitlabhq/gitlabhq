# frozen_string_literal: true

class RemoteDeplicatedAgentConfig < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class RemoteDevelopmentAgentConfig < MigrationRecord
    self.table_name = 'remote_development_agent_configs'
  end

  def up
    latest_ids = RemoteDevelopmentAgentConfig.select("DISTINCT ON (cluster_agent_id) id")
      .order("cluster_agent_id, updated_at DESC")
      .map(&:id)

    ::Gitlab::AppLogger.warn(
      message: 'removing duplicated agent configs from migration',
      agent_config_latest_ids: latest_ids
    )

    RemoteDevelopmentAgentConfig.where.not(id: latest_ids).delete_all
  end

  def down
    # removing duplicated agent config is irreversible
  end
end
