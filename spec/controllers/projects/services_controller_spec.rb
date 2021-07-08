# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ServicesController do
  include JiraServiceHelper
  include AfterNextHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { create(:user) }
  let_it_be(:service) { create(:jira_integration, project: project) }

  let(:service_params) { { username: 'username', password: 'password', url: 'http://example.com' } }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe '#test' do
    context 'when the integration is not testable' do
      it 'renders 404' do
        allow_any_instance_of(Integration).to receive(:testable?).and_return(false)

        put :test, params: project_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when validations fail' do
      let(:service_params) { { active: 'true', url: '' } }

      it 'returns error messages in JSON response' do
        put :test, params: project_params(service: service_params)

        expect(json_response['message']).to eq 'Validations failed.'
        expect(json_response['service_response']).to include "Url can't be blank"
        expect(response).to be_successful
      end
    end

    context 'success' do
      context 'with empty project' do
        let_it_be(:project) { create(:project) }

        context 'with chat notification service' do
          let_it_be(:service) { project.create_microsoft_teams_integration(webhook: 'http://webhook.com') }

          it 'returns success' do
            allow_next(::MicrosoftTeams::Notifier).to receive(:ping).and_return(true)

            put :test, params: project_params

            expect(response).to be_successful
          end
        end

        it 'returns success' do
          stub_jira_integration_test

          expect(Gitlab::HTTP).to receive(:get).with('/rest/api/2/serverInfo', any_args).and_call_original

          put :test, params: project_params(service: service_params)

          expect(response).to be_successful
        end
      end

      it 'returns success' do
        stub_jira_integration_test

        expect(Gitlab::HTTP).to receive(:get).with('/rest/api/2/serverInfo', any_args).and_call_original

        put :test, params: project_params(service: service_params)

        expect(response).to be_successful
      end

      context 'when service is configured for the first time' do
        let(:service_params) do
          {
            'active' => '1',
            'push_events' => '1',
            'token' => 'token',
            'project_url' => 'https://buildkite.com/organization/pipeline'
          }
        end

        before do
          allow_any_instance_of(ServiceHook).to receive(:execute).and_return(true)
        end

        it 'persist the object' do
          do_put

          expect(response).to be_successful
          expect(json_response).to be_empty
          expect(Integrations::Buildkite.first).to be_present
        end

        it 'creates the ServiceHook object' do
          do_put

          expect(response).to be_successful
          expect(json_response).to be_empty
          expect(Integrations::Buildkite.first.service_hook).to be_present
        end

        def do_put
          put :test, params: project_params(id: 'buildkite',
                                            service: service_params)
        end
      end
    end

    context 'failure' do
      it 'returns an error response when the integration test fails' do
        stub_request(:get, 'http://example.com/rest/api/2/serverInfo')
          .to_return(status: 404)

        put :test, params: project_params(service: service_params)

        expect(response).to be_successful
        expect(json_response).to eq(
          'error' => true,
          'message' => 'Connection failed. Please check your settings.',
          'service_response' => '',
          'test_failed' => true
        )
      end

      context 'with the Slack integration' do
        let_it_be(:integration) { build(:integrations_slack) }
        let_it_be(:service) { integration } # TODO: remove when https://gitlab.com/gitlab-org/gitlab/-/issues/330300 is complete

        it 'returns an error response when the URL is blocked' do
          put :test, params: project_params(service: { webhook: 'http://127.0.0.1' })

          expect(response).to be_successful
          expect(json_response).to eq(
            'error' => true,
            'message' => 'Connection failed. Please check your settings.',
            'service_response' => "URL 'http://127.0.0.1' is blocked: Requests to localhost are not allowed",
            'test_failed' => true
          )
        end

        it 'returns an error response when a network exception is raised' do
          expect_next(Integrations::Slack).to receive(:test).and_raise(Errno::ECONNREFUSED)

          put :test, params: project_params

          expect(response).to be_successful
          expect(json_response).to eq(
            'error' => true,
            'message' => 'Connection failed. Please check your settings.',
            'service_response' => 'Connection refused',
            'test_failed' => true
          )
        end
      end
    end
  end

  describe 'PUT #update' do
    describe 'as HTML' do
      let(:service_params) { { active: true } }
      let(:params)         { project_params(service: service_params) }

      let(:message) { 'Jira settings saved and active.' }
      let(:redirect_url) { edit_project_service_path(project, service) }

      before do
        put :update, params: params
      end

      shared_examples 'service update' do
        it 'redirects to the correct url with a flash message' do
          expect(response).to redirect_to(redirect_url)
          expect(flash[:notice]).to eq(message)
        end
      end

      context 'when param `active` is set to true' do
        let(:params) { project_params(service: service_params, redirect_to: redirect) }

        context 'when redirect_to param is present' do
          let(:redirect)     { '/redirect_here' }
          let(:redirect_url) { redirect }

          it_behaves_like 'service update'
        end

        context 'when redirect_to is an external domain' do
          let(:redirect) { 'http://examle.com' }

          it_behaves_like 'service update'
        end

        context 'when redirect_to param is an empty string' do
          let(:redirect) { '' }

          it_behaves_like 'service update'
        end
      end

      context 'when param `active` is set to false' do
        let(:service_params) { { active: false } }
        let(:message)        { 'Jira settings saved, but not active.' }

        it_behaves_like 'service update'
      end

      context 'when param `inherit_from_id` is set to empty string' do
        let(:service_params) { { inherit_from_id: '' } }

        it 'sets inherit_from_id to nil' do
          expect(service.reload.inherit_from_id).to eq(nil)
        end
      end

      context 'when param `inherit_from_id` is set to some value' do
        let(:instance_service) { create(:jira_integration, :instance) }
        let(:service_params) { { inherit_from_id: instance_service.id } }

        it 'sets inherit_from_id to value' do
          expect(service.reload.inherit_from_id).to eq(instance_service.id)
        end
      end
    end

    describe 'as JSON' do
      before do
        stub_jira_integration_test
        put :update, params: project_params(service: service_params, format: :json)
      end

      context 'when update succeeds' do
        let(:service_params) { { url: 'http://example.com' } }

        it 'returns JSON response with no errors' do
          expect(response).to be_successful
          expect(json_response).to include('active' => true, 'errors' => {})
        end
      end

      context 'when update fails' do
        let(:service_params) { { url: '' } }

        it 'returns JSON response with errors' do
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response).to include(
            'active' => true,
            'errors' => { 'url' => ['must be a valid URL', %{can't be blank}] }
          )
        end
      end
    end

    context 'Prometheus integration' do
      let_it_be(:service) { create(:prometheus_integration, project: project) }

      let(:service_params) { { manual_configuration: '1', api_url: 'http://example.com' } }

      context 'feature flag :settings_operations_prometheus_service is enabled' do
        before do
          stub_feature_flags(settings_operations_prometheus_service: true)
        end

        it 'redirects user back to edit page with alert' do
          put :update, params: project_params.merge(service: service_params)

          expect(response).to redirect_to(edit_project_service_path(project, service))
          expected_alert = "You can now manage your Prometheus settings on the <a href=\"#{project_settings_operations_path(project)}\">Operations</a> page. Fields on this page has been deprecated."

          expect(controller).to set_flash.now[:alert].to(expected_alert)
        end

        it 'does not modify integration' do
          expect { put :update, params: project_params.merge(service: service_params) }.not_to change { project.prometheus_integration.reload.attributes }
        end
      end

      context 'feature flag :settings_operations_prometheus_service is disabled' do
        before do
          stub_feature_flags(settings_operations_prometheus_service: false)
        end

        it 'modifies integration' do
          expect { put :update, params: project_params.merge(service: service_params) }.to change { project.prometheus_integration.reload.attributes }
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'Jira service' do
      let(:service_param) { 'jira' }

      before do
        get :edit, params: project_params(id: service_param)
      end

      context 'with approved services' do
        it 'renders edit page' do
          expect(response).to be_successful
        end
      end
    end

    context 'Prometheus service' do
      let(:service_param) { 'prometheus' }

      context 'feature flag :settings_operations_prometheus_service is enabled' do
        before do
          stub_feature_flags(settings_operations_prometheus_service: true)
          get :edit, params: project_params(id: service_param)
        end

        it 'renders deprecation warning notice' do
          expected_alert = "You can now manage your Prometheus settings on the <a href=\"#{project_settings_operations_path(project)}\">Operations</a> page. Fields on this page has been deprecated."
          expect(controller).to set_flash.now[:alert].to(expected_alert)
        end
      end

      context 'feature flag :settings_operations_prometheus_service is disabled' do
        before do
          stub_feature_flags(settings_operations_prometheus_service: false)
          get :edit, params: project_params(id: service_param)
        end

        it 'does not render deprecation warning notice' do
          expect(controller).not_to set_flash.now[:alert]
        end
      end
    end
  end

  private

  def project_params(opts = {})
    opts.reverse_merge(
      namespace_id: project.namespace,
      project_id: project,
      id: service.to_param
    )
  end
end
