# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills p_ci_finished_build_ch_sync_events table with finished CI builds
    # from the past 180 days. The sync events will be processed by
    # ClickHouse::DataIngestion::CiFinishedBuildsSyncService to sync data to ClickHouse.
    #
    # This is an EE-only migration. The FOSS version is a no-op.
    class BackfillCiFinishedBuildsToClickHouse < BatchedMigrationJob
      feature_category :fleet_visibility

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillCiFinishedBuildsToClickHouse.prepend_mod
