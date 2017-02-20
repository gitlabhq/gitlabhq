module API
  module V3
    class Boards < Grape::API
      before { authenticate! }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects do
        desc 'Get all project boards' do
          detail 'This feature was introduced in 8.13'
          success ::API::Entities::Board
        end
        get ':id/boards' do
          authorize!(:read_board, user_project)
          present user_project.boards, with: ::API::Entities::Board
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
            detail 'Does not include `done` list. This feature was introduced in 8.13'
            success ::API::Entities::List
          end
          get '/lists' do
            authorize!(:read_board, user_project)
            present board_lists, with: ::API::Entities::List
          end
        end
      end
    end
  end
end
