require 'spec_helper'

describe Projects::BoardListsController do
  let(:project) { create(:project_with_board) }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:label) { create(:label, project: project, name: 'Development') }

      it 'returns a successful 200 response' do
        post :create, namespace_id: project.namespace.to_param,
                      project_id: project.to_param,
                      list: { label_id: label.id },
                      format: :json

        expect(response).to have_http_status(200)
      end

      it 'returns the created list' do
        post :create, namespace_id: project.namespace.to_param,
                      project_id: project.to_param,
                      list: { label_id: label.id },
                      format: :json

        expect(response).to match_response_schema('list')
      end
    end

    context 'with invalid params' do
      it 'returns an error' do
        post :create, namespace_id: project.namespace.to_param,
                      project_id: project.to_param,
                      list: { label_id: nil },
                      format: :json

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['label']).to contain_exactly "can't be blank"
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:planning)    { create(:list, board: project.board, position: 1) }
    let!(:development) { create(:list, board: project.board, position: 2) }

    context 'with valid position' do
      it 'returns a successful 200 response' do
        patch :update, namespace_id: project.namespace.to_param,
                       project_id: project.to_param,
                       id: planning.to_param,
                       list: { position: 2 },
                       format: :json

        expect(response).to have_http_status(200)
      end

      it 'moves the list to the desired position' do
        patch :update, namespace_id: project.namespace.to_param,
                       project_id: project.to_param,
                       id: planning.to_param,
                       list: { position: 2 },
                       format: :json

        expect(planning.reload.position).to eq 2
      end
    end

    context 'with invalid position' do
      it 'returns a unprocessable entity 422 response' do
        patch :update, namespace_id: project.namespace.to_param,
                       project_id: project.to_param,
                       id: planning.to_param,
                       list: { position: 6 },
                       format: :json

        expect(response).to have_http_status(422)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        patch :update, namespace_id: project.namespace.to_param,
                       project_id: project.to_param,
                       id: 999,
                       list: { position: 2 },
                       format: :json

        expect(response).to have_http_status(404)
      end
    end
  end
  end
end
