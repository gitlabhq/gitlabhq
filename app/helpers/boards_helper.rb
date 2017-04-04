module BoardsHelper
  def board_data
    board = @board || @boards.first

    {
      endpoint: namespace_project_boards_path(@project.namespace, @project),
      board_id: board.id,
      disabled: "#{!can?(current_user, :admin_list, @project)}",
      issue_link_base: namespace_project_issues_path(@project.namespace, @project),
      root_path: root_path,
      bulk_update_path: bulk_update_namespace_project_issues_path(@project.namespace, @project),
    }
  end
end
