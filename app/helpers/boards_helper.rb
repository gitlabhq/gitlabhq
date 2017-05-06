module BoardsHelper
  def board_data
    board = @board || @boards.first

    {
      endpoint: namespace_project_boards_path(@project.namespace, @project),
      board_id: board.id,
      board_milestone_title: board&.milestone&.title,
      disabled: "#{!can?(current_user, :admin_list, @project)}",
      issue_link_base: namespace_project_issues_path(@project.namespace, @project),
      root_path: root_path,
      bulk_update_path: bulk_update_namespace_project_issues_path(@project.namespace, @project),
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
