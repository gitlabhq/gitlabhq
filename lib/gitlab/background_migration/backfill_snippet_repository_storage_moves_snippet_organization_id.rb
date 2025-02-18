# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSnippetRepositoryStorageMovesSnippetOrganizationId < BackfillDesiredShardingKeyJob
      operation_name :backfill_snippet_repository_storage_moves_snippet_organization_id
      feature_category :source_code_management
    end
  end
end
