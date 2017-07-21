module BoardsHelper
  prepend EE::BoardsHelper

  def board_data
    board = @board || @boards.first

    {
      boards_endpoint: @boards_endpoint,
      lists_endpoint: board_lists_path(board),
      board_id: board.id,
      board_milestone_title: board&.milestone&.title,
      disabled: "#{!can?(current_user, :admin_list, @project)}", # Create this permission for groups( if needed )
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
end
