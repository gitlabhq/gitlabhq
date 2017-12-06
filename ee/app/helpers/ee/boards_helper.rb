module EE
  module BoardsHelper
    def parent
      @group || @project
    end

    def board_data
      show_feature_promotion = (@project && show_promotions? &&
                                (!@project.feature_available?(:multiple_issue_boards) ||
                                 !@project.feature_available?(:scoped_issue_board) ||
                                 !@project.feature_available?(:issue_board_focus_mode)))

      data = {
        board_milestone_title: board.milestone&.name,
        board_milestone_id: board.milestone_id,
        board_assignee_username: board.assignee&.username,
        label_ids: board.label_ids,
        labels: board.labels.to_json(only: [:id, :title, :color, :text_color] ),
        board_weight: board.weight,
        focus_mode_available: parent.feature_available?(:issue_board_focus_mode),
        show_promotion: show_feature_promotion
      }

      super.merge(data)
    end

    def build_issue_link_base
      return super unless @board.group_board?

      "#{group_path(@board.group)}/:project_path/issues"
    end

    def current_board_json
      board = @board || @boards.first

      board.to_json(
        only: [:id, :name, :milestone_id, :assignee_id, :weight, :label_ids],
        include: {
          milestone: { only: [:id, :title, :name] },
          assignee: { only: [:id, :name, :username], methods: [:avatar_url] },
          labels: { only: [:title, :color, :id] }
        }
      )
    end

    def board_base_url
      if board.group_board?
        group_boards_url(@group)
      else
        super
      end
    end

    def current_board_path(board)
      @current_board_path ||= begin
        if board.group_board?
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
      super.merge(group_id: @group&.id)
    end

    def boards_link_text
      if @project.multiple_issue_boards_available?(current_user)
        s_("IssueBoards|Boards")
      else
        s_("IssueBoards|Board")
      end
    end
  end
end
