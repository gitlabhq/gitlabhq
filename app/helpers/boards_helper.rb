module BoardsHelper
  prepend EE::BoardsHelper

  def board_data
    board = @board || @boards.first

    {
      boards_endpoint: @boards_endpoint,
      lists_endpoint: board_lists_path(board),
      board_id: board.id,
      board_milestone_title: board&.milestone&.title,
      disabled: "#{!can?(current_user, :admin_list, @project)}",
      issue_link_base: @issues_path,
      root_path: root_path,
      bulk_update_path: @bulk_issues_path,
      default_avatar: image_path(default_avatar)
    }
  end

  def current_board_json
    board = @board || @boards.first

    board.to_json(
      only: [:id, :name, :milestone_id],
      include: {
        milestone: { only: [:title] }
      }
    )
  end

  def board_base_url
    if @project
      project_boards_path(@project)
    elsif @group
      group_boards_path(@group)
    end
  end

  def multiple_boards_available
    if @project
      @project.feature_available?(:multiple_issue_boards)
    elsif @group
      @group.feature_available?(:multiple_issue_boards)
    end
  end
end
