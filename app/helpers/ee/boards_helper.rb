module EE
  module BoardsHelper
    def board_data
      parent = @group || @project
      super.merge(focus_mode_available: parent.feature_available?(:issue_board_focus_mode).to_s)
    end
  end
end
