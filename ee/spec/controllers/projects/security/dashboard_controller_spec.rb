require 'spec_helper'

describe Projects::Security::DashboardController do
  let(:group)   { create(:group) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:user)    { create(:user) }

  before do
    group.add_developer(user)
  end

  describe 'GET #show' do
    let(:pipeline_1) { create(:ci_pipeline_without_jobs, project: project) }
    let(:pipeline_2) { create(:ci_pipeline_without_jobs, project: project) }
    let(:pipeline_3) { create(:ci_pipeline_without_jobs, project: project) }

    before do
      create(
        :ci_build,
        :success,
        :artifacts,
        name: 'sast',
        pipeline: pipeline_1,
        options: {
          artifacts: {
            paths: [Ci::Build::SAST_FILE]
          }
        }
      )
    end

    def show_security_dashboard(current_user = user)
      sign_in(current_user)
      get :show, namespace_id: project.namespace, project_id: project
    end

    context 'when security reports features are enabled' do
      it 'returns the latest pipeline with security reports for project' do
        stub_licensed_features(sast: true)

        show_security_dashboard

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:show)
      end
    end

    context 'when security reports features are disabled' do
      it 'returns the latest pipeline with security reports for project' do
        stub_licensed_features(sast: false, dependency_scanning: false, sast_container: false, dast: false)

        show_security_dashboard

        expect(response).to have_gitlab_http_status(404)
        expect(response).to render_template('errors/not_found')
      end
    end

    context 'with unauthorized user for security dashboard' do
      let(:guest) { create(:user) }

      it 'returns a not found 404 response' do
        stub_licensed_features(sast: true)

        group.add_guest(guest)

        show_security_dashboard guest

        expect(response).to have_gitlab_http_status(404)
        expect(response).to render_template('errors/access_denied')
      end
    end
  end
end
