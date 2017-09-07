module EE
  module BoardsResponses
    # Shared authorizations between projects and groups which
    # have different policies on EE.
    def authorize_read_list
      ability = board.group_board? ? :read_group : :read_list

      authorize_action_for!(board.parent, ability)
    end

    def authorize_read_issue
      ability = board.group_board? ? :read_group : :read_issue

      authorize_action_for!(board.parent, ability)
    end
  end
end
