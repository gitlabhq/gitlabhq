module EE
  module Boards
    module IssuesController
      def issues_finder
        if board.is_group_board?
          IssuesFinder.new(current_user, group_id: board_parent.id)
        else
          super
        end
      end

      def project
        @project ||= board.is_group_board? ? board.parent : super
      end
    end
  end
end
