module EE
  module BoardsHelper
    def board_data
      super.merge(focus_mode_available: @project.feature_available?(:issue_board_focus_mode).to_s)
    end
  end
end
