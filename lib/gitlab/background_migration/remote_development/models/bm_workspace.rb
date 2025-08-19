# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module Models
        # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
        class BmWorkspace < ::Gitlab::Database::Migration[2.3]::MigrationRecord
          include WorkspaceOperations::BmStates

          self.table_name = 'workspaces'

          belongs_to :agent, class_name: "Clusters::Agent", foreign_key: "cluster_agent_id", inverse_of: :workspaces

          # @return [Boolean]
          def desired_state_running?
            desired_state == RUNNING
          end

          # @return [BackgroundMigration::Models::BmWorkspaceAgentConfig]
          def workspaces_agent_config
            agent.unversioned_latest_workspaces_agent_config
          end
        end

        # rubocop:enable Migration/BatchedMigrationBaseClass
      end
    end
  end
end
