# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSnippetStatisticsSnippetProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_snippet_statistics_snippet_project_id
      feature_category :source_code_management
    end
  end
end
