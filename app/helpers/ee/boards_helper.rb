module EE
  module BoardsHelper
    def board_data
      parent = @group || @project
      super.merge(focus_mode_available: parent.feature_available?(:issue_board_focus_mode).to_s)
    end

    def build_issue_link_base
      return super unless @board.is_group_board?

      "/#{@board.group.path}/:project_path/issues"
    end

    def board_base_url
      return group_boards_path(@group) if @group
    end

    def board_path(board)
      @board_path ||= begin
        if board.is_group_board?
          group_board_path(current_board_parent, board)
        else
          super(board)
        end
      end
    end

    def current_board_parent
      @current_board_parent ||= @group || super
    end

    def can_admin_issue?
      can?(current_user, :admin_issue, current_board_parent)
    end

    def board_list_data
      super.merge(group_path: @group&.path)
    end

    def board_sidebar_user_data
      super.merge(group_id: @group&.path)
    end
  end
end
