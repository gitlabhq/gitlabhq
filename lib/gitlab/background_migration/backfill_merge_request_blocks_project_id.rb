# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestBlocksProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_merge_request_blocks_project_id
      feature_category :source_code_management
    end
  end
end
