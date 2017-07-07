module EE
  module Boards
    module ListService
      def execute
        raise NotImplementedError unless defined?(super)

        if project.feature_available?(:multiple_issue_boards, current_user)
          super
        else
          super.limit(1)
        end
      end
    end
  end
end
