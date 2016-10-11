module API
  # Boards API
  class Boards < Grape::API
    before { authenticate! }

    resource :projects do
      # Get the project board
      get ':id/boards' do
        authorize!(:read_board, user_project)
        present [user_project.board], with: Entities::Board
      end

      segment ':id/boards/:board_id' do
        helpers do
          def project_board
            board = user_project.board
            if params[:board_id].to_i == board.id
              board
            else
              not_found!('Board')
            end
          end

          def board_lists
            project_board.lists.destroyable
          end
        end

        # Get the lists of a project board
        # Does not include `backlog` and `done` lists
        get '/lists' do
          authorize!(:read_board, user_project)
          present board_lists, with: Entities::List
        end

        # Get a list of a project board
        get '/lists/:list_id' do
          authorize!(:read_board, user_project)
          present board_lists.find(params[:list_id]), with: Entities::List
        end

        # Create a new board list
        #
        # Parameters:
        #   id (required)           - The ID of a project
        #   label_id (required)     - The ID of an existing label
        # Example Request:
        #   POST /projects/:id/boards/:board_id/lists
        post '/lists' do
          required_attributes! [:label_id]

          unless user_project.labels.exists?(params[:label_id])
            render_api_error!({ error: "Label not found!" }, 400)
          end

          authorize!(:admin_list, user_project)

          list = ::Boards::Lists::CreateService.new(user_project, current_user,
              { label_id: params[:label_id] }).execute

          if list.valid?
            present list, with: Entities::List
          else
            render_validation_error!(list)
          end
        end

        # Moves a board list to a new position
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   board_id (required) - The ID of a board
        #   position (required) - The position of the list
        # Example Request:
        #   PUT /projects/:id/boards/:board_id/lists/:list_id
        put '/lists/:list_id' do
          list = project_board.lists.movable.find(params[:list_id])

          authorize!(:admin_list, user_project)

          moved = ::Boards::Lists::MoveService.new(user_project, current_user,
              { position: params[:position].to_i }).execute(list)

          if moved
            present list, with: Entities::List
          else
            render_api_error!({ error: "List could not be moved!" }, 400)
          end
        end

        # Delete a board list
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   board_id (required) - The ID of a board
        #   list_id (required) - The ID of a board list
        # Example Request:
        #   DELETE /projects/:id/boards/:board_id/lists/:list_id
        delete "/lists/:list_id" do
          list = board_lists.find_by(id: params[:list_id])

          authorize!(:admin_list, user_project)

          if list
            destroyed_list = ::Boards::Lists::DestroyService.new(
              user_project, current_user).execute(list)
            present destroyed_list, with: Entities::List
          else
            not_found!('List')
          end
        end
      end
    end
  end
end
