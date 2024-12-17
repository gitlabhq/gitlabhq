# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssuableSeveritiesNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_issuable_severities_namespace_id
      feature_category :team_planning
    end
  end
end
