# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWorkspaceAgentkStates < BatchedMigrationJob
      operation_name :backfill_workspace_agentk_states
      feature_category :workspaces

      # @return [Void]
      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillWorkspaceAgentkStates.prepend_mod
