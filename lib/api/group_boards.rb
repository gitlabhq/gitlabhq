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
        desc 'Get all group boards' do
          detail 'This feature was introduced in 10.6'
          success Entities::Board
        end
        params do
          use :pagination
        end
        get '/' do
          authorize!(:read_issue_board, user_group)
          present paginate(board_parent.boards.with_associations), with: Entities::Board
        end

        desc 'Find a group board' do
          detail 'This feature was introduced in 10.6'
          success Entities::Board
        end
        get '/:board_id' do
          authorize!(:read_issue_board, user_group)
          present board, with: Entities::Board
        end

        desc 'Update a group board' do
          detail 'This feature was introduced in 11.0'
          success Entities::Board
        end
        params do
          use :update_params
        end
        put '/:board_id' do
          authorize!(:admin_issue_board, board_parent)

          update_board
        end
      end

      params do
        requires :board_id, type: Integer, desc: 'The ID of a board'
      end
      segment ':id/boards/:board_id' do
        desc 'Get the lists of a group board' do
          detail 'Does not include backlog and closed lists. This feature was introduced in 10.6'
          success Entities::List
        end
        params do
          use :pagination
        end
        get '/lists' do
          authorize!(:read_issue_board, user_group)
          present paginate(board_lists), with: Entities::List
        end

        desc 'Get a list of a group board' do
          detail 'This feature was introduced in 10.6'
          success Entities::List
        end
        params do
          requires :list_id, type: Integer, desc: 'The ID of a list'
        end
        get '/lists/:list_id' do
          authorize!(:read_issue_board, user_group)
          present board_lists.find(params[:list_id]), with: Entities::List
        end

        desc 'Create a new board list' do
          detail 'This feature was introduced in 10.6'
          success Entities::List
        end
        params do
          use :list_creation_params
        end
        post '/lists' do
          authorize!(:admin_issue_board_list, user_group)

          create_list
        end

        desc 'Moves a board list to a new position' do
          detail 'This feature was introduced in 10.6'
          success Entities::List
        end
        params do
          requires :list_id,  type: Integer, desc: 'The ID of a list'
          requires :position, type: Integer, desc: 'The position of the list'
        end
        put '/lists/:list_id' do
          list = board_lists.find(params[:list_id])

          authorize!(:admin_issue_board_list, user_group)

          move_list(list)
        end

        desc 'Delete a board list' do
          detail 'This feature was introduced in 10.6'
          success Entities::List
        end
        params do
          requires :list_id, type: Integer, desc: 'The ID of a board list'
        end
        delete "/lists/:list_id" do
          authorize!(:admin_issue_board_list, user_group)
          list = board_lists.find(params[:list_id])

          destroy_list(list)
        end
      end
    end
  end
end
