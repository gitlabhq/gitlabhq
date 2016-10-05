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
    end

    context 'when format is JSON' do
      it 'returns a list of project boards' do
        create_list(:board, 2, project: project)

        list_boards format: :json

        parsed_response = JSON.parse(response.body)

        expect(response).to match_response_schema('boards')
        expect(parsed_response.length).to eq 2
      end
    end

    context 'with unauthorized user' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :read_board, project).and_return(false)
      end

      it 'returns a not found 404 response' do
        list_boards

        expect(response).to have_http_status(404)
      end
    end

    def list_boards(format: :html)
      get :index, namespace_id: project.namespace.to_param,
                  project_id: project.to_param,
                  format: format
    end
  end

  describe 'GET show' do
    it 'creates a new board when project does not have one' do
      expect { read_board }.to change(Board, :count).by(1)
    end

    it 'renders HTML template' do
      read_board

      expect(response).to render_template :show
      expect(response.content_type).to eq 'text/html'
    end

    context 'with unauthorized user' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :read_board, project).and_return(false)
      end

      it 'returns a successful 404 response' do
        read_board

        expect(response).to have_http_status(404)
      end
    end

    def read_board(format: :html)
      get :show, namespace_id: project.namespace.to_param,
                 project_id: project.to_param,
                 format: format
    end
  end
end
