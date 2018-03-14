module EE
  module Boards
    module ListService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        if parent.multiple_issue_boards_available?
          super
        else
          super.limit(1)
        end
      end
    end
  end
end
