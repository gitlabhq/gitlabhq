module API
  class Boards < Grape::API
    include BoardsResponses
    include PaginationParams

    before { authenticate! }

    helpers do
      def board_parent
        user_project
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      segment ':id/boards' do
        desc 'Get all project boards' do
          detail 'This feature was introduced in 8.13'
          success Entities::Board
        end
        params do
          use :pagination
        end
        get '/' do
          authorize!(:read_board, user_project)
          present paginate(board_parent.boards), with: Entities::Board
        end

        desc 'Find a project board' do
          detail 'This feature was introduced in 10.4'
          success Entities::Board
        end
        get '/:board_id' do
          present board, with: Entities::Board
        end
      end

      params do
        requires :board_id, type: Integer, desc: 'The ID of a board'
      end
      segment ':id/boards/:board_id' do
        desc 'Get the lists of a project board' do
          detail 'Does not include `done` list. This feature was introduced in 8.13'
          success Entities::List
        end
        params do
          use :pagination
        end
        get '/lists' do
          authorize!(:read_board, user_project)
          present paginate(board_lists), with: Entities::List
        end

        desc 'Get a list of a project board' do
          detail 'This feature was introduced in 8.13'
          success Entities::List
        end
        params do
          requires :list_id, type: Integer, desc: 'The ID of a list'
        end
        get '/lists/:list_id' do
          authorize!(:read_board, user_project)
          present board_lists.find(params[:list_id]), with: Entities::List
        end

        desc 'Create a new board list' do
          detail 'This feature was introduced in 8.13'
          success Entities::List
        end
        params do
          requires :label_id, type: Integer, desc: 'The ID of an existing label'
        end
        post '/lists' do
          unless available_labels_for(user_project).exists?(params[:label_id])
            render_api_error!({ error: 'Label not found!' }, 400)
          end

          authorize!(:admin_list, user_project)

          create_list
        end

        desc 'Moves a board list to a new position' do
          detail 'This feature was introduced in 8.13'
          success Entities::List
        end
        params do
          requires :list_id,  type: Integer, desc: 'The ID of a list'
          requires :position, type: Integer, desc: 'The position of the list'
        end
        put '/lists/:list_id' do
          list = board_lists.find(params[:list_id])

          authorize!(:admin_list, user_project)

          move_list(list)
        end

        desc 'Delete a board list' do
          detail 'This feature was introduced in 8.13'
          success Entities::List
        end
        params do
          requires :list_id, type: Integer, desc: 'The ID of a board list'
        end
        delete "/lists/:list_id" do
          authorize!(:admin_list, user_project)
          list = board_lists.find(params[:list_id])

          destroy_list(list)
        end
      end
    end
  end
end
