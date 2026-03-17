# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSnippetRepositoryStatesSnippetProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_snippet_repository_states_snippet_project_id
      feature_category :geo_replication

      def backfill_via_table_primary_key
        'snippet_id'
      end
    end
  end
end
