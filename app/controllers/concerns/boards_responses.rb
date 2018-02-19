module BoardsResponses
  include Gitlab::Utils::StrongMemoize

  def board_params
    params.require(:board).permit(:name, :weight, :milestone_id, :assignee_id, label_ids: [])
  end

  def parent
    strong_memoize(:parent) do
      group? ? group : project
    end
  end

  def boards_path
    if group?
      group_boards_path(parent)
    else
      project_boards_path(parent)
    end
  end

  def board_path(board)
    if group?
      group_board_path(parent, board)
    else
      project_board_path(parent, board)
    end
  end

  def group?
    instance_variable_defined?(:@group)
  end

  def authorize_read_list
    ability = board.group_board? ? :read_group : :read_list

    authorize_action_for!(board.parent, ability)
  end

  def authorize_read_issue
    ability = board.group_board? ? :read_group : :read_issue

    authorize_action_for!(board.parent, ability)
  end

  def authorize_update_issue
    authorize_action_for!(issue, :admin_issue)
  end

  def authorize_create_issue
    authorize_action_for!(project, :admin_issue)
  end

  def authorize_admin_list
    authorize_action_for!(board.parent, :admin_list)
  end

  def authorize_action_for!(resource, ability)
    return render_403 unless can?(current_user, ability, resource)
  end

  def respond_with_boards
    respond_with(@boards) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def respond_with_board
    respond_with(@board) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def serialize_as_json(resource)
    resource.as_json(only: [:id])
  end

  def respond_with(resource)
    respond_to do |format|
      format.html
      format.json do
        render json: serialize_as_json(resource)
      end
    end
  end
end
