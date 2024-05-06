# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # No op on ce
    class DisableAllowRunnerRegistrationOnNamespaceSettingsForGitlabCom < BatchedMigrationJob
      feature_category :fleet_visibility
      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::DisableAllowRunnerRegistrationOnNamespaceSettingsForGitlabCom.prepend_mod
