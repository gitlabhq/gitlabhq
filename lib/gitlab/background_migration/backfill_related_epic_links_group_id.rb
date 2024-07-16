# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillRelatedEpicLinksGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_related_epic_links_group_id
      feature_category :portfolio_management
    end
  end
end
