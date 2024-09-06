# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills mappings between root namespaces and all agents within the root namespace
    # that have remote development module enabled
    # For more details, check: https://gitlab.com/gitlab-org/gitlab/-/issues/454411
    class BackfillRootNamespaceClusterAgentMappings < BatchedMigrationJob
      feature_category :workspaces

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillRootNamespaceClusterAgentMappings.prepend_mod
