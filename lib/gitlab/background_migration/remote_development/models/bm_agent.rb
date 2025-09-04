# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module Models
        # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
        class BmAgent < ::Gitlab::Database::Migration[2.3]::MigrationRecord
          self.table_name = 'cluster_agents'

          has_one :unversioned_latest_workspaces_agent_config,
            class_name: 'RemoteDevelopment::Models::BmWorkspaceAgentConfig',
            inverse_of: :agent,
            foreign_key: :cluster_agent_id

          has_many :workspaces,
            class_name: 'RemoteDevelopment::Models::BmWorkspace',
            inverse_of: :agent,
            foreign_key: :cluster_agent_id
        end

        # rubocop:enable Migration/BatchedMigrationBaseClass
      end
    end
  end
end
