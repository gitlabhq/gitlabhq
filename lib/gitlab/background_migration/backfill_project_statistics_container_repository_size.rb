# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Back-fill container_registry_size for project_statistics
    class BackfillProjectStatisticsContainerRepositorySize < Gitlab::BackgroundMigration::BatchedMigrationJob
      feature_category :database

      def perform
        # no-op
      end
    end
  end
end

Gitlab::BackgroundMigration::BackfillProjectStatisticsContainerRepositorySize.prepend_mod_with('Gitlab::BackgroundMigration::BackfillProjectStatisticsContainerRepositorySize') # rubocop:disable Layout/LineLength
