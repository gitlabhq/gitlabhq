require 'spec_helper'

describe Projects::BuildsController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, :public) }

  before do
    sign_in(user)
  end

  describe 'GET status.json' do
    context 'when accessing status' do
      let(:status) do
        Gitlab::Ci::Status::Success.new(double('object'), double('user'))
      end

      before do
        pipeline = create(:ci_pipeline, project: project)
        build = create(:ci_build, pipeline: pipeline, status: :success)
        get :status, namespace_id: project.namespace,
                     project_id: project,
                     id: build.id,
                     format: :json
      end

      it 'return a correct pipeline status' do
        expect(response).to have_http_status(:ok)
        expect(json_response['favicon']).to eq status.favicon
      end
    end
  end
end
