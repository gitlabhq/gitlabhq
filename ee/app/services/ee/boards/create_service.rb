module EE
  module Boards
    module CreateService
      extend ::Gitlab::Utils::Override

      override :can_create_board?
      def can_create_board?
        parent.multiple_issue_boards_available? || super
      end
    end
  end
end
