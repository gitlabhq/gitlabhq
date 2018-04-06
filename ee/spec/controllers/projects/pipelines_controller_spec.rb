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

    context 'with a sast artifact' do
      before do
        create(
          :ci_build,
          :success,
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

      context 'with feature enabled' do
        before do
          allow(License).to receive(:feature_available?).and_return(true)

          get :security, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template :show
        end
      end

      context 'with feature disabled' do
        before do
          get :security, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to have_gitlab_http_status(:redirect)
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end

    context 'without sast artifact' do
      context 'with feature enabled' do
        before do
          allow(License).to receive(:feature_available?).and_return(true)

          get :security, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to have_gitlab_http_status(:redirect)
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end

      context 'with feature disabled' do
        before do
          get :security, namespace_id: project.namespace, project_id: project, id: pipeline
        end

        it do
          expect(response).to have_gitlab_http_status(:redirect)
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end
  end
end
