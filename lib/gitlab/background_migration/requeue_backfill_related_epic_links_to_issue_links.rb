# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- BackfillRelatedEpicLinksToIssueLinks inherits from BatchedMigrationJob.
    class RequeueBackfillRelatedEpicLinksToIssueLinks < BackfillRelatedEpicLinksToIssueLinks
      operation_name :requeue_backfill_issue_links_with_related_epic_links
      feature_category :team_planning
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
