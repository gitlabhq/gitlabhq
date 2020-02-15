# frozen_string_literal: true

require 'spec_helper'

describe Projects::Settings::OperationsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
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

  context 'incident management' do
    describe 'GET #show' do
      context 'with existing setting' do
        let!(:incident_management_setting) do
          create(:project_incident_management_setting, project: project)
        end

        it 'loads existing setting' do
          get :show, params: project_params(project)

          expect(controller.helpers.project_incident_management_setting)
            .to eq(incident_management_setting)
        end
      end

      context 'without an existing setting' do
        it 'builds a new setting' do
          get :show, params: project_params(project)

          expect(controller.helpers.project_incident_management_setting).to be_new_record
        end
      end
    end

    describe 'PATCH #update' do
      let(:params) do
        {
          incident_management_setting_attributes: {
            create_issue: 'false',
            send_email: 'false',
            issue_template_key: 'some-other-template'
          }
        }
      end

      it_behaves_like 'PATCHable'

      context 'updating each incident management setting' do
        let(:project) { create(:project) }
        let(:new_incident_management_settings) { {} }

        before do
          project.add_maintainer(user)
        end

        shared_examples 'a gitlab tracking event' do |params, event_key|
          it "creates a gitlab tracking event #{event_key}" do
            new_incident_management_settings = params

            expect(Gitlab::Tracking).to receive(:event)
              .with('IncidentManagement::Settings', event_key, kind_of(Hash))

            patch :update, params: project_params(project, incident_management_setting_attributes: new_incident_management_settings)

            project.reload
          end
        end

        it_behaves_like 'a gitlab tracking event', { create_issue: '1' }, 'enabled_issue_auto_creation_on_alerts'
        it_behaves_like 'a gitlab tracking event', { create_issue: '0' }, 'disabled_issue_auto_creation_on_alerts'
        it_behaves_like 'a gitlab tracking event', { issue_template_key: 'template' }, 'enabled_issue_template_on_alerts'
        it_behaves_like 'a gitlab tracking event', { issue_template_key: nil }, 'disabled_issue_template_on_alerts'
        it_behaves_like 'a gitlab tracking event', { send_email: '1' }, 'enabled_sending_emails'
        it_behaves_like 'a gitlab tracking event', { send_email: '0' }, 'disabled_sending_emails'
      end
    end
  end

  context 'error tracking' do
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

  context 'metrics dashboard setting' do
    describe 'PATCH #update' do
      let(:params) do
        {
          metrics_setting_attributes: {
            external_dashboard_url: 'https://gitlab.com'
          }
        }
      end

      it_behaves_like 'PATCHable'
    end
  end

  context 'grafana integration' do
    describe 'PATCH #update' do
      let(:params) do
        {
          grafana_integration_attributes: {
            grafana_url: 'https://grafana.gitlab.com',
            token: 'eyJrIjoicDRlRTREdjhhOEZ5WjZPWXUzazJOSW0zZHJUejVOd3IiLCJuIjoiVGVzdCBLZXkiLCJpZCI6MX0=',
            enabled: 'true'
          }
        }
      end

      it_behaves_like 'PATCHable'
    end
  end

  context 'prometheus integration' do
    describe 'PATCH #update' do
      let(:params) do
        {
          prometheus_integration_attributes: {
            manual_configuration: '0',
            api_url: 'https://gitlab.prometheus.rocks'
          }
        }
      end

      context 'feature flag :settings_operations_prometheus_service is enabled' do
        before do
          stub_feature_flags(settings_operations_prometheus_service: true)
        end

        it_behaves_like 'PATCHable'
      end

      context 'feature flag :settings_operations_prometheus_service is disabled' do
        before do
          stub_feature_flags(settings_operations_prometheus_service: false)
        end

        it_behaves_like 'PATCHable' do
          let(:permitted_params) do
            ActionController::Parameters.new(params.except(:prometheus_integration_attributes)).permit!
          end
        end
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
