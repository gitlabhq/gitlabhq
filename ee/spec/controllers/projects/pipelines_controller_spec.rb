require 'spec_helper'

describe Projects::PipelinesController do
  set(:user) { create(:user) }
  set(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)

    sign_in(user)
  end

  describe 'GET security' do
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    let(:build) do
      create(
        :ci_build,
        :artifacts,
        name: 'sast',
        pipeline: pipeline,
        options: {
          artifacts: {
            paths: [Ci::Build::SAST_FILE]
          }
        }
      )
    end

    before do
      build
      get :security, namespace_id: project.namespace, project_id: project, id: pipeline
    end

    it do
      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template :show
    end
  end
end
