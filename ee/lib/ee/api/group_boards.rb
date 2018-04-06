module EE
  module API
    class GroupBoards < ::Grape::API
      include ::API::PaginationParams
      include ::API::BoardsResponses
      include BoardsResponses

      before do
        authenticate!
      end

      helpers do
        def board_parent
          user_group
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a group'
      end

      resource :groups, requirements: ::API::API::PROJECT_ENDPOINT_REQUIREMENTS do
        segment ':id/boards' do
          desc 'Create a group board' do
            detail 'This feature was introduced in 10.4'
            success ::API::Entities::Board
          end
          params do
            requires :name, type: String, desc: 'The board name'
          end
          post '/' do
            authorize!(:admin_board, board_parent)

            create_board
          end

          desc 'Delete a group board' do
            detail 'This feature was introduced in 10.4'
            success ::API::Entities::Board
          end
          delete '/:board_id' do
            authorize!(:admin_board, board_parent)

            delete_board
          end
        end
      end
    end
  end
end
