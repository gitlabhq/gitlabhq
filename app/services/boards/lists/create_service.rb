module Boards
  module Lists
    class CreateService
      def initialize(project, params = {})
        @board  = project.board
        @params = params.dup
      end

      def execute
        board.lists.create(params.merge(position: position))
      end

      private

      attr_reader :board, :params

      def position
        board.lists.size
      end
    end
  end
end
