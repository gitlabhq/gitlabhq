module Boards
  class UsersController < Boards::ApplicationController
    # Enumerates all users that are members of the board parent
    # If board parent is a project it only enumerates project members
    # If board parent is a group it enumerates all members of current group,
    # ancestors, and descendants
    def index
      user_ids = finder_service
        .execute(include_descendants: true)
        .non_invite
        .select(:user_id)

      users = User.where(id: user_ids)

      render json: UserSerializer.new.represent(users)
    end

    private

    def finder_service
      @service ||=
        if board_parent.is_a?(Group)
          GroupMembersFinder.new(board_parent)
        else
          MembersFinder.new(board_parent, current_user)
        end
    end
  end
end
