require 'spec_helper'

describe Projects::BuildsController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, :public) }

  before do
    sign_in(user)
  end

  describe 'GET status.json' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, pipeline: pipeline) }
    let(:status) { build.detailed_status(double('user')) }

    before do
      get :status, namespace_id: project.namespace,
                   project_id: project,
                   id: build.id,
                   format: :json
    end

    it 'return a detailed build status in json' do
      expect(response).to have_http_status(:ok)
      expect(json_response['text']).to eq status.text
      expect(json_response['label']).to eq status.label
      expect(json_response['icon']).to eq status.icon
      expect(json_response['favicon']).to eq status.favicon
    end
  end
end
