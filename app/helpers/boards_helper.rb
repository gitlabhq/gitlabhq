# frozen_string_literal: true

module BoardsHelper
  def board
    @board
  end

  def board_data
    {
      board_id: board.id,
      disabled: board.disabled_for?(current_user).to_s,
      root_path: root_path,
      full_path: full_path,
      can_update: can_update?.to_s,
      can_admin_list: can_admin_list?.to_s,
      can_admin_board: can_admin_board?.to_s,
      time_tracking_limit_to_hours: Gitlab::CurrentSettings.time_tracking_limit_to_hours.to_s,
      parent: current_board_parent.model_name.param_key,
      group_id: group_id,
      labels_filter_base_path: build_issue_link_base,
      labels_fetch_path: labels_fetch_path,
      labels_manage_path: labels_manage_path,
      releases_fetch_path: releases_fetch_path,
      board_type: board.to_type,
      has_missing_boards: has_missing_boards?.to_s,
      multiple_boards_available: multiple_boards_available?.to_s,
      board_base_url: board_base_url,
      wi: work_items_show_data(board_namespace, current_user)
    }
  end

  def board_namespace
    board.group_board? ? @group : @project
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
      "/:project_path/-/issues"
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

  def releases_fetch_path
    if board.group_board?
      group_releases_path(@group)
    else
      project_releases_path(@project)
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

  # Boards are hidden when extra boards were created but the license does not allow multiple boards
  def has_missing_boards?
    !multiple_boards_available? && current_board_parent.boards.size > 1
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

  def can_admin_board?
    can?(current_user, :admin_issue_board, current_board_parent)
  end
end

BoardsHelper.prepend_mod_with('BoardsHelper')
