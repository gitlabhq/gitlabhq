module Boards
  class UsersFinder
    def initialize(board, current_user = nil)
      @board = board
      @current_user = current_user
    end

    def execute
      finder_service.execute(include_descendants: true).non_invite
    end

    private

    # rubocop: disable CodeReuse/Finder
    def finder_service
      @finder_service ||=
        if @board.parent.is_a?(Group)
          GroupMembersFinder.new(@board.parent)
        else
          MembersFinder.new(@board.parent, @current_user)
        end
    end
    # rubocop: enable CodeReuse/Finder
  end
end
