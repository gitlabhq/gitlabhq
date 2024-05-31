# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBoardsEpicBoardLabelsGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_boards_epic_board_labels_group_id
      feature_category :portfolio_management
    end
  end
end
