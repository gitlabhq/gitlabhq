require 'spec_helper'

describe Projects::Settings::SlacksController do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'GET show' do
    def redirect_url(project)
      edit_project_service_path(
        project,
        project.build_gitlab_slack_application_service
      )
    end

    def stub_service(result)
      service = double
      expect(service).to receive(:execute).and_return(result)
      expect(Projects::SlackApplicationInstallService)
        .to receive(:new).with(project, user, anything).and_return(service)
    end

    it 'calls service and redirects with no alerts if result is successful' do
      stub_service(status: :success)

      get :slack_auth, namespace_id: project.namespace, project_id: project

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(redirect_url(project))
      expect(flash[:alert]).to be_nil
    end

    it 'calls service and redirects with the alert if there is error' do
      stub_service(status: :error, message: 'error')

      get :slack_auth, namespace_id: project.namespace, project_id: project

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(redirect_url(project))
      expect(flash[:alert]).to eq('error')
    end
  end
end
