module Boards
  module Lists
    class GenerateService < BaseService
      def execute(board)
        return false unless board.lists.movable.empty?

        List.transaction do
          label_params.each { |params| create_list(board, params) }
        end

        true
      end

      private

      def create_list(board, params)
        label = find_or_create_label(params)
        Lists::CreateService.new(project, current_user, label_id: label.id).execute(board)
      end

      def find_or_create_label(params)
        project.labels.create_with(color: params[:color])
                      .find_or_create_by(name: params[:name])
      end

      def label_params
        [
          { name: 'To Do', color: '#F0AD4E' },
          { name: 'Doing', color: '#5CB85C' }
        ]
      end
    end
  end
end
