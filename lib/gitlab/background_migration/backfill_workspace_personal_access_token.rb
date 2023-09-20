# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # No op on ce
    class BackfillWorkspacePersonalAccessToken < BatchedMigrationJob
      feature_category :remote_development
      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillWorkspacePersonalAccessToken.prepend_mod_with('Gitlab::BackgroundMigration::BackfillWorkspacePersonalAccessToken') # rubocop:disable Layout/LineLength
