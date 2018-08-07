module EE
  module API
    module BoardsResponses
      extend ActiveSupport::Concern

      included do
        helpers do
          def create_board
            forbidden! unless board_parent.multiple_issue_boards_available?

            board =
              ::Boards::CreateService.new(board_parent, current_user, { name: params[:name] }).execute

            present board, with: ::API::Entities::Board
          end

          def update_board
            service = ::Boards::UpdateService.new(board_parent, current_user, declared_params)
            service.execute(board)

            if board.valid?
              present board, with: ::API::Entities::Board
            else
              bad_request!("Failed to save board #{board.errors.messages}")
            end
          end

          def delete_board
            forbidden! unless board_parent.multiple_issue_boards_available?

            destroy_conditionally!(board) do |board|
              service = ::Boards::DestroyService.new(board_parent, current_user)
              service.execute(board)
            end
          end

          def create_list_params
            params.slice(:label_id, :milestone_id, :assignee_id)
          end

          # Overrides API::BoardsResponses authorize_list_type_resource!
          def authorize_list_type_resource!
            if params[:label_id] && !available_labels_for(board_parent).exists?(params[:label_id])
              render_api_error!({ error: 'Label not found!' }, 400)
            end

            if milestone_id = params[:milestone_id]
              milestones = ::Boards::MilestonesFinder.new(board, current_user).execute

              unless milestones.find_by(id: milestone_id)
                render_api_error!({ error: 'Milestone not found!' }, 400)
              end
            end

            if assignee_id = params[:assignee_id]
              users = ::Boards::UsersFinder.new(board, current_user).execute

              unless users.find_by(user_id: assignee_id)
                render_api_error!({ error: 'User not found!' }, 400)
              end
            end
          end

          # Overrides API::BoardsResponses list_creation_params
          params :list_creation_params do
            optional :label_id, type: Integer, desc: 'The ID of an existing label'
            optional :milestone_id, type: Integer, desc: 'The ID of an existing milestone'
            optional :assignee_id, type: Integer, desc: 'The ID of an assignee'
            exactly_one_of :label_id, :milestone_id, :assignee_id
          end

          params :update_params do
            optional :name, type: String, desc: 'The board name'
            optional :assignee_id, type: Integer, desc: 'The ID of a user to associate with board'
            optional :milestone_id, type: Integer, desc: 'The ID of a milestone to associate with board'
            optional :labels, type: String, desc: 'Comma-separated list of label names'
            optional :weight, type: Integer, desc: 'The weight of the board'
          end
        end
      end
    end
  end
end
