# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiPipelineMessagesProjectId < BackfillDesiredShardingKeyPartitionJob
      operation_name :backfill_ci_pipeline_messages_project_id
      feature_category :continuous_integration
    end
  end
end
