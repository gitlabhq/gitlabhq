# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBoardsEpicListsGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_boards_epic_lists_group_id
      feature_category :portfolio_management
    end
  end
end
