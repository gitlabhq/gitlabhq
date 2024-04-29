# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillWikiRepositoryStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_wiki_repository_states_project_id
      feature_category :geo_replication
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
