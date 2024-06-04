# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWikiPageSlugsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_wiki_page_slugs_project_id
      feature_category :wiki
    end
  end
end
