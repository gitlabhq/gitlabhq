# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSnippetRepositoriesSnippetOrganizationId < BackfillDesiredShardingKeyJob
      operation_name :backfill_snippet_repositories_snippet_organization_id
      feature_category :source_code_management
    end
  end
end
