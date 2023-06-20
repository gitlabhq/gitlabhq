# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::SlacksController, feature_category: :integrations do
  let_it_be_with_refind(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  def redirect_url(project)
    edit_project_settings_integration_path(
      project,
      Integrations::GitlabSlackApplication.to_param
    )
  end

  describe 'GET slack_auth' do
    def stub_service(result)
      service = double
      expect(service).to receive(:execute).and_return(result)
      expect(Projects::SlackApplicationInstallService)
        .to receive(:new).with(project, user, anything).and_return(service)
    end

    context 'when valid CSRF token is provided' do
      before do
        allow(controller).to receive(:check_oauth_state).and_return(true)
      end

      it 'calls service and redirects with no alerts if result is successful' do
        stub_service(status: :success)

        get :slack_auth, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url(project))
        expect(flash[:alert]).to be_nil
        expect(session[:slack_install_success]).to be(true)
      end

      it 'calls service and redirects with the alert if there is error' do
        stub_service(status: :error, message: 'error')

        get :slack_auth, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url(project))
        expect(flash[:alert]).to eq('error')
      end
    end

    context 'when no CSRF token is provided' do
      it 'returns 403' do
        get :slack_auth, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when there was an OAuth error' do
      it 'redirects with an alert' do
        get :slack_auth, params: { namespace_id: project.namespace, project_id: project, error: 'access_denied' }

        expect(flash[:alert]).to eq('Access denied')
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url(project))
      end
    end
  end

  describe 'POST update' do
    let_it_be(:integration) { create(:gitlab_slack_application_integration, project: project) }

    let(:params) do
      { namespace_id: project.namespace, project_id: project, slack_integration: { alias: new_alias } }
    end

    context 'when alias is valid' do
      let(:new_alias) { 'foo' }

      it 'updates the record' do
        expect do
          post :update, params: params
        end.to change { integration.reload.slack_integration.alias }.to(new_alias)
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url(project))
      end
    end

    context 'when alias is invalid' do
      let(:new_alias) { '' }

      it 'does not update the record' do
        expect do
          post :update, params: params
        end.not_to change { integration.reload.slack_integration.alias }
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('projects/settings/slacks/edit')
      end
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the record' do
      create(:gitlab_slack_application_integration, project: project)

      expect do
        delete :destroy, params: { namespace_id: project.namespace, project_id: project }
      end.to change { project.gitlab_slack_application_integration.reload.slack_integration }.to(nil)
      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to(redirect_url(project))
    end
  end
end
