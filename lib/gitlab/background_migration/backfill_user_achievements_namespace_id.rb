# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillUserAchievementsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_user_achievements_namespace_id
      feature_category :user_profile
    end
  end
end
