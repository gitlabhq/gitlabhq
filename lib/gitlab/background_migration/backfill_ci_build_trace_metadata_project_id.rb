# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiBuildTraceMetadataProjectId < BackfillDesiredShardingKeyPartitionJob
      operation_name :backfill_ci_build_trace_metadata_project_id
      feature_category :continuous_integration
    end
  end
end
