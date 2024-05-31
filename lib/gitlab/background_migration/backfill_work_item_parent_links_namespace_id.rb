# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWorkItemParentLinksNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_work_item_parent_links_namespace_id
      feature_category :team_planning
    end
  end
end
