# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDesignUserMentionsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_design_user_mentions_namespace_id
      feature_category :team_planning
    end
  end
end
