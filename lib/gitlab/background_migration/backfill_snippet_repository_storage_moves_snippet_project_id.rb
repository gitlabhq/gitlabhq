# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSnippetRepositoryStorageMovesSnippetProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_snippet_repository_storage_moves_snippet_project_id
      feature_category :source_code_management
    end
  end
end
