# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSnippetUserMentionsSnippetOrganizationId < BackfillDesiredShardingKeyJob
      operation_name :backfill_snippet_user_mentions_snippet_organization_id
      feature_category :source_code_management
    end
  end
end
