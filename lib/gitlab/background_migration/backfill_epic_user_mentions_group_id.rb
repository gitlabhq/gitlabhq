# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillEpicUserMentionsGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_epic_user_mentions_group_id
      feature_category :team_planning
    end
  end
end
