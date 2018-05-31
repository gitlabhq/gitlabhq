module EE
  module Boards
    module ListService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        if parent.multiple_issue_boards_available?
          super
        else
          # When multiple issue boards is not available
          # user is only allowed to view the default shown board

          # We could use just one query but MYSQL does not support nested queries using LIMIT.
          boards.where(id: super.first).reorder(nil)
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
