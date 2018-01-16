module EE
  module Boards
    module CreateService
      extend ::Gitlab::Utils::Override

      override :can_create_board?
      def can_create_board?
        parent.feature_available?(:multiple_issue_boards) || super
      end
    end
  end
end
