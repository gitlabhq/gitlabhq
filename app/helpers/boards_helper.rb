# frozen_string_literal: true

module BoardsHelper
  def board
    @board ||= @board || @boards.first
  end

  def board_data
    {
      boards_endpoint: @boards_endpoint,
      lists_endpoint: board_lists_path(board),
      board_id: board.id,
      disabled: board.disabled_for?(current_user).to_s,
      root_path: root_path,
      full_path: full_path,
      bulk_update_path: @bulk_issues_path,
      can_update: can_update?.to_s,
      can_admin_list: can_admin_list?.to_s,
      time_tracking_limit_to_hours: Gitlab::CurrentSettings.time_tracking_limit_to_hours.to_s,
      recent_boards_endpoint: recent_boards_path,
      parent: current_board_parent.model_name.param_key,
      group_id: group_id,
      labels_filter_base_path: build_issue_link_base,
      labels_fetch_path: labels_fetch_path,
      labels_manage_path: labels_manage_path,
      board_type: board.to_type
    }
  end

  def group_id
    return @group.id if board.group_board?

    @project&.group&.id
  end

  def full_path
    if board.group_board?
      @group.full_path
    else
      @project.full_path
    end
  end

  def build_issue_link_base
    if board.group_board?
      "#{group_path(@board.group)}/:project_path/issues"
    else
      project_issues_path(@project)
    end
  end

  def labels_fetch_path
    if board.group_board?
      group_labels_path(@group, format: :json, only_group_labels: true, include_ancestor_groups: true)
    else
      project_labels_path(@project, format: :json, include_ancestor_groups: true)
    end
  end

  def labels_manage_path
    if board.group_board?
      group_labels_path(@group)
    else
      project_labels_path(@project)
    end
  end

  def board_base_url
    if board.group_board?
      group_boards_url(@group)
    else
      project_boards_path(@project)
    end
  end

  def multiple_boards_available?
    current_board_parent.multiple_issue_boards_available?
  end

  def current_board_path(board)
    @current_board_path ||= if board.group_board?
                              group_board_path(current_board_parent, board)
                            else
                              project_board_path(current_board_parent, board)
                            end
  end

  def current_board_parent
    @current_board_parent ||= @group || @project
  end

  def current_board_namespace
    @current_board_namespace = board.group_board? ? @group : @project.namespace
  end

  def can_update?
    can?(current_user, :admin_issue, board)
  end

  def can_admin_list?
    can?(current_user, :admin_issue_board_list, current_board_parent)
  end

  def can_admin_issue?
    can?(current_user, :admin_issue, current_board_parent)
  end

  def board_list_data
    include_descendant_groups = @group&.present?

    {
      toggle: "dropdown",
      list_labels_path: labels_filter_path_with_defaults(only_group_labels: true, include_ancestor_groups: true),
      labels: labels_filter_path_with_defaults(only_group_labels: true, include_descendant_groups: include_descendant_groups),
      labels_endpoint: @labels_endpoint,
      namespace_path: @namespace_path,
      project_path: @project&.path,
      group_path: @group&.path
    }
  end

  def recent_boards_path
    recent_project_boards_path(@project) if current_board_parent.is_a?(Project)
  end

  def serializer
    CurrentBoardSerializer.new
  end

  def current_board_json
    serializer.represent(board).as_json
  end
end

BoardsHelper.prepend_mod_with('BoardsHelper')
