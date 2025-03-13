# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSnippetStatisticsSnippetOrganizationId < BackfillDesiredShardingKeyJob
      operation_name :backfill_snippet_statistics_snippet_organization_id
      feature_category :source_code_management
    end
  end
end
