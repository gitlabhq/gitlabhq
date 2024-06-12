# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillReleaseLinksProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_release_links_project_id
      feature_category :release_orchestration
    end
  end
end
