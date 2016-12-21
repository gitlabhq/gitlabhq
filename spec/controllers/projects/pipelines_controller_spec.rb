require 'spec_helper'

describe Projects::PipelinesController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, :public) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  before do
    sign_in(user)
  end

  describe 'GET stages.json' do
    context 'when accessing existing stage' do
      before do
        create(:ci_build, pipeline: pipeline, stage: 'build')

        get_stage('build')
      end

      it 'returns html source for stage dropdown' do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template('projects/pipelines/_stage')
        expect(json_response).to include('html')
      end
    end

    context 'when accessing unknown stage' do
      before do
        get_stage('test')
      end

      it 'responds with not found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    def get_stage(name)
      get :stage, namespace_id: project.namespace.path,
                  project_id: project.path,
                  id: pipeline.id,
                  stage: name,
                  format: :json
    end
  end
end
