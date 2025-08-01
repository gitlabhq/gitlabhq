# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module Models
        # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
        class BmWorkspaceAgent < ::Gitlab::Database::Migration[2.3]::MigrationRecord
          include WorkspaceOperations::BmStates

          self.table_name = 'cluster_agents'

          has_one :unversioned_latest_workspaces_agent_config,
            class_name: 'RemoteDevelopment::WorkspacesAgentConfig',
            inverse_of: :agent,
            foreign_key: :cluster_agent_id
        end
        # rubocop:enable Migration/BatchedMigrationBaseClass
      end
    end
  end
end
