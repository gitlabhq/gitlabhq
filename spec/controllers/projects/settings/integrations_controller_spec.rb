require 'spec_helper'

describe Projects::Settings::IntegrationsController do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'GET show' do
    it 'renders show with 200 status code' do
      get :show, namespace_id: project.namespace, project_id: project

      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
    end
  end

  context 'Sets correct services list' do
    it 'enables SlackSlashCommandsService and disables GitlabSlackApplication' do
      get :show, namespace_id: project.namespace, project_id: project

      services = assigns(:services).map(&:type)

      expect(services).to include('SlackSlashCommandsService')
      expect(services).not_to include('GitlabSlackApplicationService')
    end

    it 'enables GitlabSlackApplication and disables SlackSlashCommandsService' do
      stub_application_setting(slack_app_enabled: true)
      allow(::Gitlab).to receive(:com?).and_return(true)

      get :show, namespace_id: project.namespace, project_id: project

      services = assigns(:services).map(&:type)

      expect(services).to include('GitlabSlackApplicationService')
      expect(services).not_to include('SlackSlashCommandsService')
    end
  end
end
