# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillResourceWeightEventsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_resource_weight_events_namespace_id
      feature_category :team_planning
    end
  end
end
