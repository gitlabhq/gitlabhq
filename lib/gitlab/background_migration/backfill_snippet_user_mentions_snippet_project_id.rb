# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSnippetUserMentionsSnippetProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_snippet_user_mentions_snippet_project_id
      feature_category :source_code_management
    end
  end
end
