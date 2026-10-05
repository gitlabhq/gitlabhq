# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Copies Duo workflows into ai_governance_sessions with the same mapping as
    # Ai::Governance::Session.sync_from_workflow!, for workflows the live sync never saw.
    class BackfillAiGovernanceSessionsFromDuoWorkflows < BatchedMigrationJob
      feature_category :compliance_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillAiGovernanceSessionsFromDuoWorkflows.prepend_mod
