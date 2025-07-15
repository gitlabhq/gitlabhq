# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # EE-only: ee/lib/ee/gitlab/background_migration/fix_secret_tokens_for_http_destinations.rb
    class FixSecretTokensForHttpDestinations < BatchedMigrationJob
      feature_category :audit_events

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::FixSecretTokensForHttpDestinations.prepend_mod
