# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillResourceLinkEventsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_resource_link_events_namespace_id
      feature_category :team_planning
    end
  end
end
