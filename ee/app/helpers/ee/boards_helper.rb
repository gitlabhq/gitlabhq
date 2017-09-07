module EE
  module BoardsHelper
    def board_data
      super.merge(focus_mode_available: @project.feature_available?(:issue_board_focus_mode).to_s,
                  show_promotion: (show_promotions? && (!@project.feature_available?(:multiple_issue_boards) || !@project.feature_available?(:issue_board_milestone) || !@project.feature_available?(:issue_board_focus_mode))).to_s)
    end
  end
end
