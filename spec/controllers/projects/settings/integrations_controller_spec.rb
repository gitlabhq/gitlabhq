# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::IntegrationsController do
  include JiraIntegrationHelpers
  include AfterNextHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { create(:user) }
  let_it_be(:jira_integration) { create(:jira_integration, project: project) }

  let(:integration) { jira_integration }
  let(:integration_params) { { username: 'username', password: 'password', url: 'http://example.com' } }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  it_behaves_like Integrations::Actions do
    let(:integration_attributes) { { project: project } }

    let(:routing_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: integration.to_param
      }
    end
  end

  describe 'GET index' do
    it 'renders index with 200 status code' do
      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end
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
      let(:integration_params) { { active: 'true', url: '' } }

      it 'returns error messages in JSON response' do
        put :test, params: project_params(service: integration_params)

        expect(json_response['message']).to eq 'Validations failed.'
        expect(json_response['service_response']).to include "Url can't be blank"
        expect(response).to be_successful
      end
    end

    context 'when successful' do
      context 'with empty project' do
        let_it_be(:project) { create(:project) }

        context 'with chat notification integration' do
          let_it_be(:teams_integration) { project.create_microsoft_teams_integration(webhook: 'http://webhook.com') }

          let(:integration) { teams_integration }

          it 'returns success' do
            allow_next(::MicrosoftTeams::Notifier).to receive(:ping).and_return(true)

            put :test, params: project_params

            expect(response).to be_successful
          end
        end

        it 'returns success' do
          stub_jira_integration_test

          expect(Gitlab::HTTP).to receive(:get).with('/rest/api/2/serverInfo', any_args).and_call_original

          put :test, params: project_params(service: integration_params)

          expect(response).to be_successful
        end
      end

      it 'returns success' do
        stub_jira_integration_test

        expect(Gitlab::HTTP).to receive(:get).with('/rest/api/2/serverInfo', any_args).and_call_original

        put :test, params: project_params(service: integration_params)

        expect(response).to be_successful
      end

      context 'when service is configured for the first time' do
        let(:integration_params) do
          {
            'active' => '1',
            'push_events' => '1',
            'token' => 'token',
            'project_url' => 'https://buildkite.com/organization/pipeline'
          }
        end

        before do
          allow_next(ServiceHook).to receive(:execute).and_return(true)
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
                                            service: integration_params)
        end
      end
    end

    context 'when unsuccessful', :clean_gitlab_redis_rate_limiting do
      it 'returns an error response when the integration test fails' do
        stub_request(:get, 'http://example.com/rest/api/2/serverInfo')
          .to_return(status: 404)

        put :test, params: project_params(service: integration_params)

        expect(response).to be_successful
        expect(json_response).to eq(
          'error' => true,
          'message' => 'Connection failed. Check your integration settings.',
          'service_response' => '',
          'test_failed' => true
        )
      end

      context 'with the Slack integration' do
        let_it_be(:integration) { build(:integrations_slack) }

        it 'returns an error response when the URL is blocked' do
          put :test, params: project_params(service: { webhook: 'http://127.0.0.1' })

          expect(response).to be_successful
          expect(json_response).to eq(
            'error' => true,
            'message' => 'Connection failed. Check your integration settings.',
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
            'message' => 'Connection failed. Check your integration settings.',
            'service_response' => 'Connection refused',
            'test_failed' => true
          )
        end
      end
    end

    context 'when the endpoint receives requests above the limit', :freeze_time, :clean_gitlab_redis_rate_limiting do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:rate_limits)
          .and_return(project_testing_integration: { threshold: 1, interval: 1.minute })
      end

      it 'prevents making test requests' do
        stub_jira_integration_test

        expect_next_instance_of(::Integrations::Test::ProjectService) do |service|
          expect(service).to receive(:execute).and_return(http_status: 200)
        end

        2.times { post :test, params: project_params(service: integration_params) }

        expect(response.body).to eq(_('This endpoint has been requested too many times. Try again later.'))
        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end
  end

  describe 'PUT #update' do
    describe 'as HTML' do
      let(:integration_params) { { active: true } }
      let(:params) { project_params(service: integration_params) }

      let(:message) { 'Jira settings saved and active.' }
      let(:redirect_url) { edit_project_settings_integration_path(project, integration) }

      before do
        stub_jira_integration_test

        put :update, params: params
      end

      shared_examples 'integration update' do
        it 'redirects to the correct url with a flash message' do
          expect(response).to redirect_to(redirect_url)
          expect(flash[:notice]).to eq(message)
        end
      end

      context 'when update fails' do
        let(:integration_params) { { url: 'https://new.com', password: '' } }

        it 'renders the edit form' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:edit)
          expect(integration.reload.url).not_to eq('https://new.com')
        end
      end

      context 'when param `active` is set to true' do
        let(:params) { project_params(service: integration_params, redirect_to: redirect) }

        context 'when redirect_to param is present' do
          let(:redirect)     { '/redirect_here' }
          let(:redirect_url) { redirect }

          it_behaves_like 'integration update'
        end

        context 'when redirect_to is an external domain' do
          let(:redirect) { 'http://examle.com' }

          it_behaves_like 'integration update'
        end

        context 'when redirect_to param is an empty string' do
          let(:redirect) { '' }

          it_behaves_like 'integration update'
        end
      end

      context 'when param `active` is set to false' do
        let(:integration_params) { { active: false } }
        let(:message) { 'Jira settings saved, but not active.' }

        it_behaves_like 'integration update'
      end

      context 'when param `inherit_from_id` is set to empty string' do
        let(:integration_params) { { inherit_from_id: '' } }

        it 'sets inherit_from_id to nil' do
          expect(integration.reload.inherit_from_id).to eq(nil)
        end
      end

      context 'when param `inherit_from_id` is set to an instance integration' do
        let(:instance_integration) do
          create(:jira_integration, :instance, url: 'http://instance.com', password: 'instance')
        end

        let(:integration_params) do
          { inherit_from_id: instance_integration.id, url: 'http://custom.com', password: 'custom' }
        end

        it 'ignores submitted params and inherits instance settings' do
          expect(integration.reload).to have_attributes(
            inherit_from_id: instance_integration.id,
            url: instance_integration.url,
            password: instance_integration.password
          )
        end
      end

      context 'when param `inherit_from_id` is set to a group integration' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:jira_integration) { create(:jira_integration, project: project) }

        let(:group_integration) do
          create(:jira_integration, :group, group: group, url: 'http://group.com', password: 'group')
        end

        let(:integration_params) do
          { inherit_from_id: group_integration.id, url: 'http://custom.com', password: 'custom' }
        end

        it 'ignores submitted params and inherits group settings' do
          expect(integration.reload).to have_attributes(
            inherit_from_id: group_integration.id,
            url: group_integration.url,
            password: group_integration.password
          )
        end
      end

      context 'when param `inherit_from_id` is set to an unrelated group' do
        let_it_be(:group) { create(:group) }

        let(:group_integration) do
          create(:jira_integration, :group, group: group, url: 'http://group.com', password: 'group')
        end

        let(:integration_params) do
          { inherit_from_id: group_integration.id, url: 'http://custom.com', password: 'custom' }
        end

        it 'ignores the param and saves the submitted settings' do
          expect(integration.reload).to have_attributes(
            inherit_from_id: nil,
            url: 'http://custom.com',
            password: 'custom'
          )
        end
      end
    end

    describe 'as JSON' do
      before do
        stub_jira_integration_test
        put :update, params: project_params(service: integration_params, format: :json)
      end

      context 'when update succeeds' do
        let(:integration_params) { { url: 'http://example.com', password: 'password' } }

        it 'returns success response' do
          expect(response).to be_successful
          expect(json_response).to include(
            'active' => true,
            'errors' => {}
          )
        end
      end

      context 'when update fails with missing password' do
        let(:integration_params) { { url: 'http://example.com' } }

        it 'returns JSON response errors' do
          expect(response).not_to be_successful
          expect(json_response).to include(
            'active' => true,
            'errors' => {
              'password' => ["can't be blank"]
            }
          )
        end
      end

      context 'when update fails with invalid URL' do
        let(:integration_params) { { url: '', password: 'password' } }

        it 'returns JSON response with errors' do
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response).to include(
            'active' => true,
            'errors' => { 'url' => ['must be a valid URL', "can't be blank"] }
          )
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'with Jira service' do
      let(:integration_param) { 'jira' }

      before do
        get :edit, params: project_params(id: integration_param)
      end

      context 'with approved services' do
        it 'renders edit page' do
          expect(response).to be_successful
        end
      end
    end
  end

  private

  def project_params(opts = {})
    opts.reverse_merge(
      namespace_id: project.namespace,
      project_id: project,
      id: integration.to_param
    )
  end
end
