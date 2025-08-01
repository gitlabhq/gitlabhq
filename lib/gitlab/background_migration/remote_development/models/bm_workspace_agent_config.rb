# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module Models
        # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
        class BmWorkspaceAgentConfig < ::Gitlab::Database::Migration[2.3]::MigrationRecord
          include WorkspaceOperations::BmStates

          self.table_name = 'workspace_agent_configs'

          belongs_to :agent,
            class_name: 'Clusters::Agent', foreign_key: 'cluster_agent_id',
            inverse_of: :unversioned_latest_workspaces_agent_config
        end
        # rubocop:enable Migration/BatchedMigrationBaseClass
      end
    end
  end
end
