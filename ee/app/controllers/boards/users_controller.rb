module Boards
  class UsersController < Boards::ApplicationController
    # Enumerates all users that are members of the board parent
    # If board parent is a project it only enumerates project members
    # If board parent is a group it enumerates all members of current group,
    # ancestors, and descendants
    # rubocop: disable CodeReuse/ActiveRecord
    def index
      user_ids = user_finder.execute.select(:user_id)

      users = User.where(id: user_ids)

      render json: UserSerializer.new.represent(users)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def user_finder
      @user_finder ||= Boards::UsersFinder.new(board, current_user)
    end
  end
end
