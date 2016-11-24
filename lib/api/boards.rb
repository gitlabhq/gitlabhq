module API
  # Boards API
  class Boards < Grape::API
    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects do
      desc 'Get all project boards' do
        detail 'This feature was introduced in 8.13'
        success Entities::Board
      end
      get ':id/boards' do
        authorize!(:read_board, user_project)
        present user_project.boards, with: Entities::Board
      end

      params do
        requires :board_id, type: Integer, desc: 'The ID of a board'
      end
      segment ':id/boards/:board_id' do
        helpers do
          def project_board
            board = user_project.boards.first

            if params[:board_id] == board.id
              board
            else
              not_found!('Board')
            end
          end

          def board_lists
            project_board.lists.destroyable
          end
        end

        desc 'Get the lists of a project board' do
          detail 'Does not include `backlog` and `done` lists. This feature was introduced in 8.13'
          success Entities::List
        end
        get '/lists' do
          authorize!(:read_board, user_project)
          present board_lists, with: Entities::List
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
          unless available_labels.exists?(params[:label_id])
            render_api_error!({ error: 'Label not found!' }, 400)
          end

          authorize!(:admin_list, user_project)

          service = ::Boards::Lists::CreateService.new(user_project, current_user,
            { label_id: params[:label_id] })

          list = service.execute(project_board)

          if list.valid?
            present list, with: Entities::List
          else
            render_validation_error!(list)
          end
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
          list = project_board.lists.movable.find(params[:list_id])

          authorize!(:admin_list, user_project)

          service = ::Boards::Lists::MoveService.new(user_project, current_user,
              { position: params[:position] })

          if service.execute(list)
            present list, with: Entities::List
          else
            render_api_error!({ error: "List could not be moved!" }, 400)
          end
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

          service = ::Boards::Lists::DestroyService.new(user_project, current_user)

          if service.execute(list)
            present list, with: Entities::List
          else
            render_api_error!({ error: 'List could not be deleted!' }, 400)
          end
        end
      end
    end
  end
end
