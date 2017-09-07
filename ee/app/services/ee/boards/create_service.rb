module EE
  module Boards
    module CreateService
      def can_create_board?
        raise NotImplementedError unless defined?(super)

        parent.feature_available?(:multiple_issue_boards) || super
      end
    end
  end
end
