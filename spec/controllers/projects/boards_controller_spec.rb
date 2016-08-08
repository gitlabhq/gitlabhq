require 'spec_helper'

describe Projects::BoardsController do
  let(:project) { create(:empty_project) }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'GET #show' do
    context 'when project does not have a board' do
      it 'creates a new board' do
        expect { read_board }.to change(Board, :count).by(1)
      end
    end

    context 'when format is HTML' do
      it 'renders HTML template' do
        read_board

        expect(response).to render_template :show
        expect(response.content_type).to eq 'text/html'
      end

      context 'with unauthorized user' do
        it 'returns a successful 404 response' do
          allow(Ability.abilities).to receive(:allowed?).with(user, :read_project, project).and_return(true)
          allow(Ability.abilities).to receive(:allowed?).with(user, :read_board, project).and_return(false)

          read_board

          expect(response).to have_http_status(404)
        end
      end
    end

    context 'when format is JSON' do
      it 'returns a successful 200 response' do
        read_board format: :json

        expect(response).to have_http_status(200)
        expect(response.content_type).to eq 'application/json'
      end

      it 'returns a list of board lists' do
        board = project.create_board
        create(:backlog_list, board: board)
        create(:list, board: board)
        create(:done_list, board: board)

        read_board format: :json

        parsed_response = JSON.parse(response.body)

        expect(response).to match_response_schema('list', array: true)
        expect(parsed_response.length).to eq 3
      end

      context 'with unauthorized user' do
        it 'returns a successful 403 response' do
          allow(Ability.abilities).to receive(:allowed?).with(user, :read_project, project).and_return(true)
          allow(Ability.abilities).to receive(:allowed?).with(user, :read_board, project).and_return(false)

          read_board format: :json

          expect(response).to have_http_status(403)
        end
      end
    end

    def read_board(format: :html)
      get :show, namespace_id: project.namespace.to_param,
                 project_id: project.to_param,
                 format: format
    end
  end
end
