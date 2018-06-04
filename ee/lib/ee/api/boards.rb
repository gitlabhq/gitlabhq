module EE
  module API
    class Boards < ::Grape::API
      include ::API::PaginationParams
      include ::API::BoardsResponses
      include BoardsResponses

      before { authenticate! }

      helpers do
        def board_parent
          user_project
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: ::API::API::PROJECT_ENDPOINT_REQUIREMENTS do
        segment ':id/boards' do
          desc 'Create a project board' do
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

          desc 'Update a project board' do
            detail 'This feature was introduced in 11.0'
            success ::API::Entities::Board
          end
          params do
            use :update_params
          end
          put '/:board_id' do
            authorize!(:admin_board, board_parent)

            update_board
          end

          desc 'Delete a project board' do
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
