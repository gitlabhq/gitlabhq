module BoardsHelper
  def board_data
    board = @board || @boards.first

    {
      endpoint: project_boards_path(@project),
      board_id: board.id,
      disabled: "#{!can?(current_user, :admin_list, @project)}",
      issue_link_base: project_issues_path(@project),
      root_path: root_path,
      bulk_update_path: bulk_update_project_issues_path(@project),
      default_avatar: image_path(default_avatar)
    }
  end
end
