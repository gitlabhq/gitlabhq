# frozen_string_literal: true

module API
  class GroupBoards < ::API::Base
    include BoardsResponses
    include PaginationParams

    prepend_mod_with('API::BoardsResponses') # rubocop: disable Cop/InjectEnterpriseEditionModule

    feature_category :team_planning
    urgency :low

    before { authenticate! }

    helpers do
      def board_parent
        user_group
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/boards' do
        desc 'List all group issue boards in a group' do
          detail 'Lists all group issue boards for a specified group.'
          success Entities::Board
          tags ['boards']
        end
        params do
          use :pagination
        end
        route_setting :authorization, permissions: :read_issue_board, boundary_type: :group
        get '/' do
          authorize!(:read_issue_board, user_group)
          present paginate(board_parent.boards.with_associations), with: Entities::Board
        end

        desc 'Retrieve a group issue board' do
          detail 'Retrieves a specified group issue board.'
          success Entities::Board
          tags ['boards']
        end
        params do
          requires :board_id, type: Integer, desc: 'The ID of a board'
        end
        route_setting :authorization, permissions: :read_issue_board, boundary_type: :group
        get '/:board_id' do
          authorize!(:read_issue_board, user_group)
          present board, with: Entities::Board
        end

        desc 'Update a group issue board' do
          detail 'Updates a specified group issue board.'
          success Entities::Board
          tags ['boards']
        end
        params do
          requires :board_id, type: Integer, desc: 'The ID of a board'
          use :update_params
        end
        route_setting :authorization, permissions: :update_issue_board, boundary_type: :group
        put '/:board_id' do
          authorize!(:admin_issue_board, board_parent)

          update_board
        end
      end

      params do
        requires :board_id, type: Integer, desc: 'The ID of a board'
      end
      segment ':id/boards/:board_id' do
        desc 'List all group issue board lists' do
          detail 'Lists all group issue board lists for a specified board. Does not include `open` and `closed` lists.'
          success Entities::List
          tags ['boards']
        end
        params do
          use :pagination
        end
        route_setting :authorization, permissions: :read_issue_board_list, boundary_type: :group
        get '/lists' do
          authorize!(:read_issue_board, user_group)
          present paginate(board_lists), with: Entities::List
        end

        desc 'Retrieve a group issue board list' do
          detail 'Retrieves a specified group issue board list.'
          success Entities::List
          tags ['boards']
        end
        params do
          requires :list_id, type: Integer, desc: 'The ID of a list'
        end
        route_setting :authorization, permissions: :read_issue_board_list, boundary_type: :group
        get '/lists/:list_id' do
          authorize!(:read_issue_board, user_group)
          present board_lists.find(params[:list_id]), with: Entities::List
        end

        desc 'Create a group issue board list' do
          detail 'Creates a group issue board list for a specified board.'
          success Entities::List
          tags ['boards']
        end
        params do
          use :list_creation_params
        end
        route_setting :authorization, permissions: :create_issue_board_list, boundary_type: :group
        post '/lists' do
          authorize!(:admin_issue_board_list, user_group)

          create_list
        end

        desc 'Update a group issue board list' do
          detail 'Updates a specified group issue board list. This call is used to change list position.'
          success Entities::List
          tags ['boards']
        end
        params do
          requires :list_id,  type: Integer, desc: 'The ID of a list'
          requires :position, type: Integer, desc: 'The position of the list'
        end
        route_setting :authorization, permissions: :update_issue_board_list, boundary_type: :group
        put '/lists/:list_id' do
          list = board_lists.find(params[:list_id])

          authorize!(:admin_issue_board_list, user_group)

          move_list(list)
        end

        desc 'Delete a group issue board list' do
          detail 'Deletes a specified group issue board list. Only for administrators and users with the Owner ' \
            'role for the group.'
          success Entities::List
          tags ['boards']
        end
        params do
          requires :list_id, type: Integer, desc: 'The ID of a board list'
        end
        route_setting :authorization, permissions: :delete_issue_board_list, boundary_type: :group
        delete "/lists/:list_id" do
          authorize!(:admin_issue_board_list, user_group)
          list = board_lists.find(params[:list_id])

          destroy_list(list)
        end
      end
    end
  end
end
