# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWorkItemProgressesNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_work_item_progresses_namespace_id
      feature_category :team_planning
    end
  end
end
