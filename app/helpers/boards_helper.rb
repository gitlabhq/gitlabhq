module BoardsHelper
  prepend EE::BoardsHelper

  def board_data
    board = @board || @boards.first

    {
      endpoint: project_boards_path(@project),
      board_id: board.id,
      board_milestone_title: board&.milestone&.title,
      disabled: "#{!can?(current_user, :admin_list, @project)}",
      issue_link_base: project_issues_path(@project),
      root_path: root_path,
      bulk_update_path: bulk_update_project_issues_path(@project),
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
