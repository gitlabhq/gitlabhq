# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # No op on ce
    class UpdateWorkspacesConfigVersion3 < BatchedMigrationJob
      feature_category :workspaces
      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::UpdateWorkspacesConfigVersion3.prepend_mod_with('Gitlab::BackgroundMigration::UpdateWorkspacesConfigVersion3')
