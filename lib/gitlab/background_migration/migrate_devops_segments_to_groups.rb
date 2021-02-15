# frozen_string_literal: true
module Gitlab
  module BackgroundMigration
    # EE-specific migration
    class MigrateDevopsSegmentsToGroups
      def perform
        # no-op for CE
      end
    end
  end
end

Gitlab::BackgroundMigration::MigrateDevopsSegmentsToGroups.prepend_if_ee('EE::Gitlab::BackgroundMigration::MigrateDevopsSegmentsToGroups')
