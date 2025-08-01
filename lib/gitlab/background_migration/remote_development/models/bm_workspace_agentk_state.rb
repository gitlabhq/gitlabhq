# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module Models
        # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
        class BmWorkspaceAgentkState < ::Gitlab::Database::Migration[2.3]::MigrationRecord
          self.table_name = 'workspace_agentk_states'
        end
        # rubocop:enable Migration/BatchedMigrationBaseClass
      end
    end
  end
end
