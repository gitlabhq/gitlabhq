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
end
