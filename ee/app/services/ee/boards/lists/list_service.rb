module EE
  module Boards
    module Lists
      module ListService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(board)
          return super if board.parent.feature_available?(:board_assignee_lists)

          super.where.not(list_type: ::List.list_types[:assignee])
        end
      end
    end
  end
end
