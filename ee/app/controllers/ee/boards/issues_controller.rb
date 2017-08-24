module EE
  module Boards
    module IssuesController
      def issues_finder
        return super unless board.group_board?

        IssuesFinder.new(current_user, group_id: board_parent.id)
      end

      def project
        @project ||= board.group_board? ? super : board.parent
      end
    end
  end
end
