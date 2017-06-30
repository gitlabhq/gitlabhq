require 'spec_helper'

describe Projects::BoardsController do # rubocop:disable RSpec/FilePath
  let(:project) { create(:empty_project) }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'GET index' do
    it 'returns a list of project boards including milestones' do
      create(:board, project: project, milestone: create(:milestone, project: project))
      create(:board, project: project, milestone_id: Milestone::Upcoming.id)

      list_boards format: :json

      parsed_response = JSON.parse(response.body)

      expect(response).to match_response_schema('boards')
      expect(parsed_response.length).to eq 2
    end

    def list_boards(format: :html)
      get :index, namespace_id: project.namespace,
                  project_id: project,
                  format: format
    end
  end

  describe 'POST create' do
    context 'with the multiple issue boards available' do
      before do
        stub_licensed_features(multiple_issue_boards: true)
      end

      context 'with valid params' do
        it 'returns a successful 200 response' do
          create_board name: 'Backend'

          expect(response).to have_http_status(200)
        end

        it 'returns the created board' do
          create_board name: 'Backend'

          expect(response).to match_response_schema('board')
        end
      end

      context 'with invalid params' do
        it 'returns an unprocessable entity 422 response' do
          create_board name: nil

          expect(response).to have_http_status(422)
        end
      end

      context 'with unauthorized user' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :admin_board, project).and_return(false)
        end

        it 'returns a not found 404 response' do
          create_board name: 'Backend'

          expect(response.content_type).to eq 'application/json'
          expect(response).to have_http_status(404)
        end
      end
    end

    it 'renders a 404 when multiple issue boards are not available' do
      stub_licensed_features(multiple_issue_boards: false)

      create_board name: 'Backend'

      expect(response).to have_http_status(404)
    end

    def create_board(name:)
      post :create, namespace_id: project.namespace.to_param,
                    project_id: project.to_param,
                    board: { name: name },
                    format: :json
    end
  end

  describe 'PATCH update' do
    let(:board) { create(:board, project: project, name: 'Backend') }

    context 'with valid params' do
      it 'returns a successful 200 response' do
        update_board board: board, name: 'Frontend'

        expect(response).to have_http_status(200)
      end

      it 'returns the updated board' do
        update_board board: board, name: 'Frontend'

        expect(response).to match_response_schema('board')
      end
    end

    context 'with invalid params' do
      it 'returns an unprocessable entity 422 response' do
        update_board board: board, name: nil

        expect(response).to have_http_status(422)
      end
    end

    context 'with invalid board id' do
      it 'returns a not found 404 response' do
        update_board board: 999, name: 'Frontend'

        expect(response).to have_http_status(404)
      end
    end

    context 'with unauthorized user' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :admin_board, project).and_return(false)
      end

      it 'returns a not found 404 response' do
        update_board board: board, name: 'Backend'

        expect(response.content_type).to eq 'application/json'
        expect(response).to have_http_status(404)
      end
    end

    def update_board(board:, name:)
      patch :update, namespace_id: project.namespace.to_param,
                     project_id: project.to_param,
                     id: board.to_param,
                     board: { name: name },
                     format: :json
    end
  end

  describe 'DELETE destroy' do
    let!(:boards) { create_pair(:board, project: project) }
    let(:board)   { project.boards.first }

    context 'with valid board id' do
      it 'redirects to the issue boards page' do
        remove_board board: board

        expect(response).to redirect_to(project_boards_path(project))
      end

      it 'removes board from project' do
        expect { remove_board board: board }.to change(project.boards, :size).by(-1)
      end
    end

    context 'with invalid board id' do
      it 'returns a not found 404 response' do
        remove_board board: 999

        expect(response).to have_http_status(404)
      end
    end

    context 'with unauthorized user' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :admin_board, project).and_return(false)
      end

      it 'returns a not found 404 response' do
        remove_board board: board

        expect(response).to have_http_status(404)
      end
    end

    def remove_board(board:)
      delete :destroy, namespace_id: project.namespace.to_param,
                       project_id: project.to_param,
                       id: board.to_param,
                       format: :html
    end
  end
end
