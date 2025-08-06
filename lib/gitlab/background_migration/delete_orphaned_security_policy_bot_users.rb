# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedSecurityPolicyBotUsers < BatchedMigrationJob
      feature_category :security_policy_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::DeleteOrphanedSecurityPolicyBotUsers.prepend_mod
