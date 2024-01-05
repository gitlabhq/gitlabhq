# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # No op on ce
    class UpdateWorkspacesConfigVersion3 < BatchedMigrationJob
      feature_category :remote_development
      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::UpdateWorkspacesConfigVersion3.prepend_mod_with('Gitlab::BackgroundMigration::UpdateWorkspacesConfigVersion3') # rubocop:disable Layout/LineLength -- Injecting extension modules must be done on the last line of this file, outside of any class or module definitions
