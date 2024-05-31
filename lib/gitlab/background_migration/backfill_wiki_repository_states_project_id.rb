# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWikiRepositoryStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_wiki_repository_states_project_id
      feature_category :geo_replication
    end
  end
end
