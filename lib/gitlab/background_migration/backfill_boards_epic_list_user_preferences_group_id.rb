# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBoardsEpicListUserPreferencesGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_boards_epic_list_user_preferences_group_id
      feature_category :portfolio_management
    end
  end
end
