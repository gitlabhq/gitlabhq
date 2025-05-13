# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixStringConfigHashesInstanceStreamingDestinations < BatchedMigrationJob
      # This batched background migration is EE-only
      # Migration file:
      # ee/lib/ee/gitlab/background_migration/fix_string_config_hashes_instance_streaming_destinations.rb
      feature_category :audit_events

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::FixStringConfigHashesInstanceStreamingDestinations.prepend_mod
