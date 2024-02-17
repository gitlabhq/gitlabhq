# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class PurgeSecurityScansWithEmptyFindingData < BatchedMigrationJob
      feature_category :vulnerability_management

      def perform
        # no-op for CE version
      end
    end
  end
end

Gitlab::BackgroundMigration::PurgeSecurityScansWithEmptyFindingData.prepend_mod
