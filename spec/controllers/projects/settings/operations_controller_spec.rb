# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::OperationsController, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, maintainers: user) }

  before do
    sign_in(user)
  end

  shared_examples 'PATCHable' do
    let(:operations_update_service) { instance_double(::Projects::Operations::UpdateService) }
    let(:operations_url) { project_settings_operations_url(project) }

    let(:permitted_params) do
      ActionController::Parameters.new(params).permit!
    end

    context 'format json' do
      context 'when update succeeds' do
        it 'returns success status' do
          stub_operations_update_service_returning(status: :success)

          patch :update,
            params: project_params(project, params),
            format: :json

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq('status' => 'success')
          expect(flash[:notice]).to eq('Your changes have been saved')
        end
      end

      context 'when update fails' do
        it 'returns error' do
          stub_operations_update_service_returning(
            status: :error,
            message: 'error message'
          )

          patch :update,
            params: project_params(project, params),
            format: :json

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('error message')
        end
      end
    end

    private

    def stub_operations_update_service_returning(return_value = {})
      expect(::Projects::Operations::UpdateService)
        .to receive(:new).with(project, user, permitted_params)
        .and_return(operations_update_service)
      expect(operations_update_service).to receive(:execute)
        .and_return(return_value)
    end
  end

  describe 'GET #show' do
    it 'renders show template' do
      get :show, params: project_params(project)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:show)
    end

    context 'with insufficient permissions' do
      before do
        project.add_reporter(user)
      end

      it 'renders 404' do
        get :show, params: project_params(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'as an anonymous user' do
      before do
        sign_out(user)
      end

      it 'redirects to signup page' do
        get :show, params: project_params(project)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with insufficient permissions' do
      before do
        project.add_reporter(user)
      end

      it 'renders 404' do
        patch :update, params: project_params(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'as an anonymous user' do
      before do
        sign_out(user)
      end

      it 'redirects to signup page' do
        patch :update, params: project_params(project)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'incident management', feature_category: :incident_management do
    describe 'GET #show' do
      render_views

      context 'with existing setting' do
        let!(:incident_management_setting) do
          create(:project_incident_management_setting, project: project)
        end

        it 'loads existing setting' do
          get :show, params: project_params(project)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include('data-auto-close-incident="true"')
        end
      end

      context 'without an existing setting' do
        it 'builds a new setting' do
          get :show, params: project_params(project)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include('data-auto-close-incident="true"')
        end
      end
    end

    describe 'PATCH #update' do
      let(:params) do
        {
          incident_management_setting_attributes: {
            create_issue: 'false',
            send_email: 'false',
            issue_template_key: 'some-other-template',
            pagerduty_active: 'true',
            auto_close_incident: 'true'
          }
        }
      end

      it_behaves_like 'PATCHable'

      context 'updating each incident management setting' do
        let(:new_incident_management_settings) { {} }

        shared_examples 'a gitlab tracking event' do |params, event_key, **args|
          it "creates a gitlab tracking event #{event_key}", :snowplow do
            new_incident_management_settings = params

            patch :update, params: project_params(project, incident_management_setting_attributes: new_incident_management_settings)

            project.reload

            expect_snowplow_event(category: 'IncidentManagement::Settings', action: event_key, **args)
          end
        end

        it_behaves_like 'a gitlab tracking event', { create_issue: '1' }, 'enabled_issue_auto_creation_on_alerts'
        it_behaves_like 'a gitlab tracking event', { create_issue: '0' }, 'disabled_issue_auto_creation_on_alerts'
        it_behaves_like 'a gitlab tracking event', { issue_template_key: 'template' }, 'enabled_issue_template_on_alerts', label: "Template name", property: "template"
        it_behaves_like 'a gitlab tracking event', { issue_template_key: nil }, 'disabled_issue_template_on_alerts', label: "Template name", property: ""
        it_behaves_like 'a gitlab tracking event', { send_email: '1' }, 'enabled_sending_emails'
        it_behaves_like 'a gitlab tracking event', { send_email: '0' }, 'disabled_sending_emails'
        it_behaves_like 'a gitlab tracking event', { pagerduty_active: '1' }, 'enabled_pagerduty_webhook'
        it_behaves_like 'a gitlab tracking event', { pagerduty_active: '0' }, 'disabled_pagerduty_webhook'
        it_behaves_like 'a gitlab tracking event', { auto_close_incident: '1' }, 'enabled_auto_close_incident'
        it_behaves_like 'a gitlab tracking event', { auto_close_incident: '0' }, 'disabled_auto_close_incident'
      end
    end

    describe 'POST #reset_pagerduty_token' do
      context 'with existing incident management setting has active PagerDuty webhook' do
        let!(:incident_management_setting) do
          create(:project_incident_management_setting, project: project, pagerduty_active: true)
        end

        let!(:old_token) { incident_management_setting.pagerduty_token }

        it 'returns newly reset token' do
          reset_pagerduty_token

          new_token = incident_management_setting.reload.pagerduty_token
          new_webhook_url = project_incidents_integrations_pagerduty_url(project, token: new_token)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['pagerduty_webhook_url']).to eq(new_webhook_url)
          expect(json_response['pagerduty_token']).to eq(new_token)
          expect(old_token).not_to eq(new_token)
        end
      end

      context 'without existing incident management setting' do
        it 'does not reset a token' do
          reset_pagerduty_token

          new_webhook_url = project_incidents_integrations_pagerduty_url(project, token: nil)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['pagerduty_webhook_url']).to eq(new_webhook_url)
          expect(project.incident_management_setting.pagerduty_token).to be_nil
        end
      end

      context 'when update fails' do
        let(:operations_update_service) { spy(:operations_update_service) }
        let(:pagerduty_token_params) do
          { incident_management_setting_attributes: { regenerate_token: true } }
        end

        before do
          expect(::Projects::Operations::UpdateService)
            .to receive(:new).with(project, user, pagerduty_token_params)
            .and_return(operations_update_service)
          expect(operations_update_service).to receive(:execute)
            .and_return(status: :error)
        end

        it 'returns unprocessable_entity' do
          reset_pagerduty_token

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response).to be_empty
        end
      end

      context 'with insufficient permissions' do
        before do
          project.add_reporter(user)
        end

        it 'returns 404' do
          reset_pagerduty_token

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'as an anonymous user' do
        before do
          sign_out(user)
        end

        it 'returns a redirect' do
          reset_pagerduty_token

          expect(response).to have_gitlab_http_status(:redirect)
        end
      end

      private

      def reset_pagerduty_token
        post :reset_pagerduty_token, params: project_params(project), format: :json
      end
    end
  end

  context 'error tracking', feature_category: :observability do
    describe 'GET #show' do
      context 'with existing setting' do
        let!(:error_tracking_setting) do
          create(:project_error_tracking_setting, project: project)
        end

        it 'loads existing setting' do
          get :show, params: project_params(project)

          expect(controller.helpers.error_tracking_setting)
            .to eq(error_tracking_setting)
        end
      end

      context 'without an existing setting' do
        it 'builds a new setting' do
          get :show, params: project_params(project)

          expect(controller.helpers.error_tracking_setting).to be_new_record
        end
      end
    end

    describe 'PATCH #update' do
      let(:params) do
        {
          error_tracking_setting_attributes: {
            enabled: '1',
            api_host: 'http://url',
            token: 'token',
            project: {
              slug: 'sentry-project',
              name: 'Sentry Project',
              organization_slug: 'sentry-org',
              organization_name: 'Sentry Org'
            }
          }
        }
      end

      it_behaves_like 'PATCHable'
    end
  end

  context 'prometheus integration' do
    describe 'POST #reset_alerting_token' do
      context 'with existing alerting setting' do
        let!(:alerting_setting) do
          create(:project_alerting_setting, project: project)
        end

        let!(:old_token) { alerting_setting.token }

        it 'returns newly reset token' do
          reset_alerting_token

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['token']).to eq(alerting_setting.reload.token)
          expect(old_token).not_to eq(alerting_setting.token)
        end
      end

      context 'without existing alerting setting' do
        it 'creates a token' do
          reset_alerting_token

          expect(response).to have_gitlab_http_status(:ok)
          expect(project.alerting_setting).not_to be_nil
          expect(json_response['token']).to eq(project.alerting_setting.token)
        end
      end

      context 'when update fails' do
        let(:operations_update_service) { spy(:operations_update_service) }
        let(:alerting_params) do
          { alerting_setting_attributes: { regenerate_token: true } }
        end

        before do
          expect(::Projects::Operations::UpdateService)
            .to receive(:new).with(project, user, alerting_params)
            .and_return(operations_update_service)
          expect(operations_update_service).to receive(:execute)
            .and_return(status: :error)
        end

        it 'returns unprocessable_entity' do
          reset_alerting_token

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response).to be_empty
        end
      end

      context 'with insufficient permissions' do
        before do
          project.add_reporter(user)
        end

        it 'returns 404' do
          reset_alerting_token

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'as an anonymous user' do
        before do
          sign_out(user)
        end

        it 'returns a redirect' do
          reset_alerting_token

          expect(response).to have_gitlab_http_status(:redirect)
        end
      end

      private

      def reset_alerting_token
        post :reset_alerting_token,
          params: project_params(project),
          format: :json
      end
    end
  end

  private

  def project_params(project, params = {})
    {
      namespace_id: project.namespace,
      project_id: project,
      project: params
    }
  end
end
