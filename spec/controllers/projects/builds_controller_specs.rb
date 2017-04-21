require 'spec_helper'

describe Projects::BuildsController do
  let(:project) { create(:empty_project, :public) }

  describe 'GET trace.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, pipeline: pipeline) }
    let(:user) { create(:user) }

    context 'when user is logged in as developer' do
      before do
        project.add_developer(user)
        sign_in(user)
        get_trace
      end

      it 'traces build log' do
        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq build.id
        expect(json_response['status']).to eq build.status
      end
    end

    context 'when user is logged in as non member' do
      before do
        sign_in(user)
        get_trace
      end

      it 'traces build log' do
        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq build.id
        expect(json_response['status']).to eq build.status
      end
    end

    def get_trace
      get :trace, namespace_id: project.namespace,
                  project_id: project,
                  id: build.id,
                  format: :json
    end
  end
end
