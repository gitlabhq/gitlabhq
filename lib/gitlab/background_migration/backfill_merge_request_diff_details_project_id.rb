# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestDiffDetailsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_merge_request_diff_details_project_id
      feature_category :geo_replication
    end
  end
end
