# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class MigrateSecurityScans
      def perform(start_id, stop_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::MigrateSecurityScans.prepend_mod_with('Gitlab::BackgroundMigration::MigrateSecurityScans')
