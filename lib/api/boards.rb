# frozen_string_literal: true

module API
  class Boards < ::API::Base
    include BoardsResponses
    include PaginationParams

    prepend_mod_with('API::BoardsResponses') # rubocop: disable Cop/InjectEnterpriseEditionModule

    feature_category :team_planning
    urgency :low

    before { authenticate! }

    helpers do
      def board_parent
        user_project
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/boards' do
        desc 'List all project issue boards' do
          detail 'Lists all issue boards in a specified project.'
          success Entities::Board
          tags ['boards']
        end
        params do
          use :pagination
        end
        route_setting :authorization, permissions: :read_issue_board, boundary_type: :project
        get '/' do
          authorize!(:read_issue_board, user_project)
          present paginate(board_parent.boards.with_associations), with: Entities::Board
        end

        desc 'Retrieve an issue board' do
          detail 'Retrieves a specified issue board in a project.'
          success Entities::Board
          tags ['boards']
        end
        route_setting :authorization, permissions: :read_issue_board, boundary_type: :project
        get '/:board_id' do
          authorize!(:read_issue_board, user_project)
          present board, with: Entities::Board
        end

        desc 'Create an issue board' do
          detail 'Creates an issue board in a specified project.'
          success Entities::Board
          tags ['boards']
        end
        params do
          requires :name, type: String, desc: 'The board name'
        end
        route_setting :authorization, permissions: :create_issue_board, boundary_type: :project
        post '/' do
          authorize!(:admin_issue_board, board_parent)

          create_board
        end

        desc 'Update an issue board' do
          detail 'Updates a specified issue board in a project.'
          success Entities::Board
          tags ['boards']
        end
        params do
          use :update_params
        end
        route_setting :authorization, permissions: :update_issue_board, boundary_type: :project
        put '/:board_id' do
          authorize!(:admin_issue_board, board_parent)

          update_board
        end

        desc 'Delete an issue board' do
          detail 'Deletes a specified issue board in a project.'
          success Entities::Board
          tags ['boards']
        end
        route_setting :authorization, permissions: :delete_issue_board, boundary_type: :project
        delete '/:board_id' do
          authorize!(:admin_issue_board, board_parent)

          delete_board
        end
      end

      params do
        requires :board_id, type: Integer, desc: 'The ID of a board'
      end
      segment ':id/boards/:board_id' do
        desc 'List all board lists in an issue board' do
          detail 'Lists all lists in a specified issue board. Does not include `open` and `closed` lists.'
          success Entities::List
          tags ['boards']
        end
        params do
          use :pagination
        end
        route_setting :authorization, permissions: :read_issue_board_list, boundary_type: :project
        get '/lists' do
          authorize!(:read_issue_board, user_project)
          present paginate(board_lists), with: Entities::List
        end

        desc 'Retrieve a board list' do
          detail 'Retrieves a specified list from an issue board.'
          success Entities::List
          tags ['boards']
        end
        params do
          requires :list_id, type: Integer, desc: 'The ID of a list'
        end
        route_setting :authorization, permissions: :read_issue_board_list, boundary_type: :project
        get '/lists/:list_id' do
          authorize!(:read_issue_board, user_project)
          present board_lists.find(params[:list_id]), with: Entities::List
        end

        desc 'Create an issue board list' do
          detail 'Creates an issue board list.'
          success Entities::List
          tags ['boards']
        end
        params do
          use :list_creation_params
        end
        route_setting :authorization, permissions: :create_issue_board_list, boundary_type: :project
        post '/lists' do
          authorize!(:admin_issue_board_list, user_project)

          create_list
        end

        desc 'Update position of a board list' do
          detail 'Updates the position of a specified list from an issue board.'
          success Entities::List
          tags ['boards']
        end
        params do
          requires :list_id,  type: Integer, desc: 'The ID of a list'
          requires :position, type: Integer, desc: 'The position of the list'
        end
        route_setting :authorization, permissions: :update_issue_board_list, boundary_type: :project
        put '/lists/:list_id' do
          list = board_lists.find(params[:list_id])

          authorize!(:admin_issue_board_list, user_project)

          move_list(list)
        end

        desc 'Delete a list from an issue board' do
          detail 'Deletes a specified list from an issue board.'
          success Entities::List
          tags ['boards']
        end
        params do
          requires :list_id, type: Integer, desc: 'The ID of a board list'
        end
        route_setting :authorization, permissions: :delete_issue_board_list, boundary_type: :project
        delete "/lists/:list_id" do
          authorize!(:admin_issue_board_list, user_project)
          list = board_lists.find(params[:list_id])

          destroy_list(list)
        end
      end
    end
  end
end
