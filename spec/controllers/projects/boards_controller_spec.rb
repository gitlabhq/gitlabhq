require 'spec_helper'

describe Projects::BoardsController do
  let(:project) { create(:empty_project) }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'GET index' do
    it 'creates a new project board when project does not have one' do
      expect { list_boards }.to change(project.boards, :count).by(1)
    end

    context 'when format is HTML' do
      it 'renders template' do
        list_boards

        expect(response).to render_template :index
        expect(response.content_type).to eq 'text/html'
      end

      context 'with unauthorized user' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :read_board, project).and_return(false)
        end

        it 'returns a not found 404 response' do
          list_boards

          expect(response).to have_http_status(404)
          expect(response.content_type).to eq 'text/html'
        end
      end
    end

    context 'when format is JSON' do
      it 'returns a list of project boards' do
        create_list(:board, 2, project: project)

        list_boards format: :json

        parsed_response = JSON.parse(response.body)

        expect(response).to match_response_schema('boards')
        expect(parsed_response.length).to eq 2
      end

      context 'with unauthorized user' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :read_board, project).and_return(false)
        end

        it 'returns a not found 404 response' do
          list_boards format: :json

          expect(response).to have_http_status(404)
          expect(response.content_type).to eq 'application/json'
        end
      end
    end

    def list_boards(format: :html)
      get :index, namespace_id: project.namespace.to_param,
                  project_id: project.to_param,
                  format: format
    end
  end

  describe 'GET show' do
    let!(:board) { create(:board, project: project) }

    context 'when format is HTML' do
      it 'renders template' do
        read_board board: board

        expect(response).to render_template :show
        expect(response.content_type).to eq 'text/html'
      end

      context 'with unauthorized user' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :read_board, project).and_return(false)
        end

        it 'returns a not found 404 response' do
          read_board board: board

          expect(response).to have_http_status(404)
          expect(response.content_type).to eq 'text/html'
        end
      end
    end

    context 'when format is JSON' do
      it 'returns project board' do
        read_board board: board, format: :json

        expect(response).to match_response_schema('board')
      end

      context 'with unauthorized user' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :read_board, project).and_return(false)
        end

        it 'returns a not found 404 response' do
          read_board board: board, format: :json

          expect(response).to have_http_status(404)
          expect(response.content_type).to eq 'application/json'
        end
      end
    end

    context 'when board does not belong to project' do
      it 'returns a not found 404 response' do
        another_board = create(:board)

        read_board board: another_board

        expect(response).to have_http_status(404)
      end
    end

    def read_board(board:, format: :html)
      get :show, namespace_id: project.namespace.to_param,
                 project_id: project.to_param,
                 id: board.to_param,
                 format: format
    end
  end

  describe 'POST create' do
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
    let!(:board) { create(:board, project: project) }

    context 'with valid board id' do
      it 'returns a successful 200 response' do
        remove_board board: board

        expect(response).to have_http_status(200)
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
                       format: :json
    end
  end
end
