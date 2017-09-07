module EE
  module Boards
    module ListService
      def execute
        raise NotImplementedError unless defined?(super)

        if parent.multiple_issue_boards_available?(current_user)
          super
        else
          super.limit(1)
        end
      end
    end
  end
end
