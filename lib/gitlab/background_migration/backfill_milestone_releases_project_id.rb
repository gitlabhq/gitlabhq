# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMilestoneReleasesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_milestone_releases_project_id
      feature_category :release_orchestration
    end
  end
end
