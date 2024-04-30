# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillWorkItemParentLinksNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_work_item_parent_links_namespace_id
      feature_category :team_planning
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
