# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::IntegrationsController, feature_category: :integrations do
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
    let(:active_services) { assigns(:integrations).map(&:model_name) }

    it 'renders index with 200 status code' do
      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end

    it 'shows Slack Slash Commands and not the GitLab for Slack app' do
      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(active_services).to include('Integrations::SlackSlashCommands')
      expect(active_services).not_to include('Integrations::GitlabSlackApplication')
    end

    context 'when the `slack_app_enabled` application setting is enabled' do
      before do
        stub_application_setting(slack_app_enabled: true)
      end

      it 'shows the GitLab for Slack app and not Slack Slash Commands' do
        get :index, params: { namespace_id: project.namespace, project_id: project }

        expect(active_services).to include('Integrations::GitlabSlackApplication')
        expect(active_services).not_to include('Integrations::SlackSlashCommands')
      end
    end
  end

  describe '#test', :clean_gitlab_redis_rate_limiting do
    let_it_be(:integration) { create(:external_wiki_integration, project: project) }

    let(:integration_params) { { external_wiki_url: 'https://example.net/wiki' } }

    it 'renders 404 when the integration is not testable' do
      allow_next_found_instance_of(integration.class) do |integration|
        allow(integration).to receive(:testable?).and_return(false)
      end

      put :test, params: project_params(service: integration_params)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response).to eq({})
    end

    it 'returns success if test is successful' do
      allow_next(Integrations::Test::ProjectService).to receive(:execute).and_return({ success: true })

      put :test, params: project_params(service: integration_params)

      expect(response).to be_successful
      expect(json_response).to eq({})
    end

    it 'returns extra given data if test is successful' do
      allow_next(Integrations::Test::ProjectService).to receive(:execute)
        .and_return({ success: true, data: { my_payload: true } })

      put :test, params: project_params(service: integration_params)

      expect(response).to be_successful
      expect(json_response).to eq({ 'my_payload' => true })
    end

    it 'does not persist assigned attributes when testing the integration' do
      original_external_wiki_url = integration.external_wiki_url
      new_external_wiki_url = 'https://example.com/wiki'
      integration_params = { active: 'true', external_wiki_url: new_external_wiki_url }

      allow_next(Integrations::Test::ProjectService).to receive(:execute).and_return({ success: true })

      put :test, params: project_params(service: integration_params)

      integration.reload

      expect(integration.external_wiki_url).to eq(original_external_wiki_url)
    end

    it 'returns an error response if the test is not successful' do
      allow_next(Integrations::Test::ProjectService).to receive(:execute).and_return({ success: false })

      put :test, params: project_params(service: integration_params)

      expect(response).to be_successful
      expect(json_response).to eq(
        'error' => true,
        'message' => 'Connection failed. Check your integration settings.',
        'service_response' => '',
        'test_failed' => true
      )
    end

    it 'returns extra given message if the test is not successful' do
      allow_next(Integrations::Test::ProjectService).to receive(:execute)
        .and_return({ success: false, result: 'Result of test' })

      put :test, params: project_params(service: integration_params)

      expect(response).to be_successful
      expect(json_response).to eq(
        'error' => true,
        'message' => 'Connection failed. Check your integration settings.',
        'service_response' => 'Result of test',
        'test_failed' => true
      )
    end

    it 'returns an error response if a network exception is raised' do
      allow_next(Integrations::Test::ProjectService).to receive(:execute).and_raise(Errno::ECONNREFUSED)

      put :test, params: project_params(service: integration_params)

      expect(response).to be_successful
      expect(json_response).to eq(
        'error' => true,
        'message' => 'Connection failed. Check your integration settings.',
        'service_response' => 'Connection refused',
        'test_failed' => true
      )
    end

    it 'returns error messages in JSON response if validations fail' do
      integration_params = { active: 'true', external_wiki_url: '' }

      put :test, params: project_params(service: integration_params)

      expect(json_response['message']).to eq 'Validations failed.'
      expect(json_response['service_response']).to eq(
        "External wiki url can't be blank, External wiki url must be a valid URL"
      )
      expect(response).to be_successful
    end

    context 'when integration has a webhook' do
      let_it_be(:integration) { create(:integrations_slack, project: project) }

      it 'returns an error response if the webhook URL is changed to one that is blocked' do
        integration_params = { webhook: 'http://127.0.0.1' }

        put :test, params: project_params(service: integration_params)

        expect(response).to be_successful
        expect(json_response).to eq(
          'error' => true,
          'message' => 'Validations failed.',
          'service_response' => "Webhook is blocked: Requests to localhost are not allowed",
          'test_failed' => false
        )
      end

      it 'ignores masked webhook param' do
        integration_params = { active: 'true', webhook: '************' }
        allow_next(Integrations::Test::ProjectService).to receive(:execute).and_return({ success: true })

        expect do
          put :test, params: project_params(service: integration_params)
        end.not_to change { integration.reload.webhook }

        expect(response).to be_successful
        expect(json_response).to eq({})
      end

      it 'creates an associated web hook record if web hook integration is configured for the first time' do
        integration_params = {
          'active' => '1',
          'issues_events' => '1',
          'push_events' => '0',
          'token' => 'my-token',
          'project_url' => 'https://buildkite.com/organization/pipeline'
        }
        allow_next(ServiceHook).to receive(:execute).and_return(true)

        expect do
          put :test, params: project_params(id: 'buildkite', service: integration_params)
        end.to change { Integrations::Buildkite.count }.from(0).to(1)

        integration = Integrations::Buildkite.take

        expect(response).to be_successful
        expect(json_response).to eq({})
        expect(integration).to have_attributes(
          project_url: 'https://buildkite.com/organization/pipeline',
          issues_events: true,
          push_events: false
        )
        expect(integration.service_hook).to have_attributes(
          url: 'https://webhook.buildkite.com/deliver/{webhook_token}',
          interpolated_url: 'https://webhook.buildkite.com/deliver/my-token'
        )
      end
    end

    context 'when the endpoint receives requests above the rate limit', :freeze_time do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:rate_limits)
          .and_return(project_testing_integration: { threshold: 1, interval: 1.minute })
      end

      it 'prevents making test requests' do
        expect_next_instance_of(::Integrations::Test::ProjectService) do |service|
          expect(service).to receive(:execute).and_return(http_status: 200)
        end

        2.times { post :test, params: project_params(service: integration_params) }

        expect(json_response).to eq(
          {
            'error' => true,
            'message' => 'This endpoint has been requested too many times. Try again later.'
          }
        )
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when prometheus integration' do
      let_it_be(:integration) { create(:prometheus_integration, project: project) }

      it 'returns 404' do
        put :test, params: project_params(service: { active: 'true' })
        # because remove_monitor_metrics feature flag is enabled
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PUT #update' do
    describe 'as HTML' do
      let(:integration_params) { { active: true } }
      let(:params) { project_params(service: integration_params) }

      let(:message) { 'Jira issues settings saved and active.' }
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
        let(:message) { 'Jira issues settings saved, but not active.' }

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

      context 'with chat notification integration' do
        let_it_be(:integration) { project.create_microsoft_teams_integration(webhook: 'http://webhook.com') }
        let(:message) { 'Microsoft Teams notifications settings saved and active.' }

        it_behaves_like 'integration update'

        context 'with masked token' do
          let(:integration_params) { { active: true, webhook: '************' } }

          it_behaves_like 'integration update'

          it 'does not update the webhook' do
            expect(integration.reload.webhook).to eq('http://webhook.com')
          end
        end
      end

      context 'with chat notification integration which masks channel params' do
        let_it_be(:integration) do
          create(:discord_integration, project: project, note_channel: 'https://discord.com/api/webhook/note')
        end

        let(:message) { 'Discord Notifications settings saved and active.' }

        it_behaves_like 'integration update'

        context 'with masked channel param' do
          let(:integration_params) { { active: true, note_channel: '************' } }

          it_behaves_like 'integration update'

          it 'does not update the channel' do
            expect(integration.reload.note_channel).to eq('https://discord.com/api/webhook/note')
          end
        end
      end

      context 'when prometheus integration' do
        let_it_be(:integration) { create(:prometheus_integration, project: project) }

        it 'returns 404' do
          # because remove_monitor_metrics feature flag is enabled
          expect(response).to have_gitlab_http_status(:not_found)
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
