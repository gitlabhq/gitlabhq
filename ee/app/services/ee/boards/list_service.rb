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

      private

      override :boards
      def boards
        super.order('LOWER(name) ASC')
      end
    end
  end
end
