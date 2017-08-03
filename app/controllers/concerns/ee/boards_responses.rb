module EE
  module BoardsResponses
    # Shared authorizations between projects and groups which
    # have different policies.
    def authorize_read_list
      ability = board.is_group_board? ? :read_group : :read_list

      authorize_action_for!(board.parent, ability)
    end

    def authorize_read_issue
      ability = board.is_group_board? ? :read_group : :read_issue

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
      respond_with(@boards)
    end

    def respond_with_board
      respond_with(@board)
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
end
