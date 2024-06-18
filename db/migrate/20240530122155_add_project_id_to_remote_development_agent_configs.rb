# frozen_string_literal: true

class AddProjectIdToRemoteDevelopmentAgentConfigs < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :remote_development_agent_configs, :project_id, :bigint
  end
end
