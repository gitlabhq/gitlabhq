# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWikiPageSlugsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_wiki_page_slugs_namespace_id
      feature_category :wiki
    end
  end
end
