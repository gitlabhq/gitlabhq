# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Clean up personal access tokens with expires_at value is nil
    # and set the value to new default 365 days
    class CleanupPersonalAccessTokensWithNilExpiresAt < BatchedMigrationJob
      feature_category :system_access

      def perform; end
    end
  end
end
