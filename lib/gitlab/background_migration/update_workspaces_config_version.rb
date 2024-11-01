# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # No op on ce
    class UpdateWorkspacesConfigVersion < BatchedMigrationJob
      feature_category :workspaces
      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::UpdateWorkspacesConfigVersion.prepend_mod_with('Gitlab::BackgroundMigration::UpdateWorkspacesConfigVersion')
