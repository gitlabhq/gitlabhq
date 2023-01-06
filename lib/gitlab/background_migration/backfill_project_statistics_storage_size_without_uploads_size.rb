# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Back-fill storage_size for project_statistics
    class BackfillProjectStatisticsStorageSizeWithoutUploadsSize < Gitlab::BackgroundMigration::BatchedMigrationJob
      feature_category :database

      def perform
        # no-op
      end
    end
  end
end

Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithoutUploadsSize.prepend_mod_with('Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithoutUploadsSize') # rubocop:disable Layout/LineLength
