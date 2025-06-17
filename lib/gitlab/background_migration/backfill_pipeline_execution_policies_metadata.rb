# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPipelineExecutionPoliciesMetadata < BatchedMigrationJob
      feature_category :security_policy_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillPipelineExecutionPoliciesMetadata.prepend_mod
