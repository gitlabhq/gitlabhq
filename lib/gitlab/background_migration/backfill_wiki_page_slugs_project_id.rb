# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillWikiPageSlugsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_wiki_page_slugs_project_id
      feature_category :wiki
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
