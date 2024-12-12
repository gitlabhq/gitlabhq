# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiBuildTraceChunksProjectId < BackfillDesiredShardingKeyPartitionJob
      operation_name :backfill_ci_build_trace_chunks_project_id
      feature_category :continuous_integration
    end
  end
end
