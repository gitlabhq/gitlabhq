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

  def multiple_boards_available?
    current_board_parent.multiple_issue_boards_available?(current_user)
  end

  def board_path(board)
    @board_path ||= begin
      if board.is_group_board?
        group_board_path(current_board_parent, board)
      else
        project_board_path(current_board_parent, board)
      end
    end
  end

  def current_board_parent
    @current_board_parent ||= @project || @group
  end

  def board_list_data
    namespace_path = current_board_parent.try(:path) || current_board_parent.namespace.try(:path)

    {
      toggle: "dropdown",
      labels: labels_filter_path(true),
      namespace_path: namespace_path,
      project_path: @project&.try(:path), # Change this one on JS to use a single property: parent_path
      group_path: @group&.try(:path) # Same here
    }
  end

  def board_sidebar_user_data
    dropdown_options = issue_assignees_dropdown_options

    {
      toggle: 'dropdown',
      field_name: 'issue[assignee_ids][]',
      first_user: current_user&.username,
      current_user: 'true',
      project_id: @project&.try(:id),
      null_user: 'true',
      multi_select: 'true',
      'dropdown-header': dropdown_options[:data][:'dropdown-header'],
      'max-select': dropdown_options[:data][:'max-select']
    }
  end
end
