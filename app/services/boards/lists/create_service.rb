module Boards
  module Lists
    class CreateService
      def initialize(project, params = {})
        @board  = project.board
        @params = params.dup
      end

      def execute
        List.transaction do
          position = find_next_position
          increment_higher_lists(position)
          create_list_at(position)
        end
      end

      private

      attr_reader :board, :params

      def find_next_position
        board.lists.label.maximum(:position).to_i + 1
      end

      def create_list_at(position)
        board.lists.create(params.merge(list_type: :label, position: position))
      end

      def increment_higher_lists(position)
        board.lists.label.where('position >= ?', position)
                         .update_all('position = position + 1')
      end
    end
  end
end
