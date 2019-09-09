# frozen_string_literal: true

require 'spec_helper'

describe Projects::ServicesController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }
  let(:service) { create(:jira_service, project: project) }
  let(:service_params) { { username: 'username', password: 'password', url: 'http://example.com' } }

  before do
    sign_in(user)
    project.add_maintainer(user)
    allow(Gitlab::UrlBlocker).to receive(:validate!).and_return([URI.parse('http://example.com'), nil])
  end

  describe '#test' do
    context 'when can_test? returns false' do
      it 'renders 404' do
        allow_any_instance_of(Service).to receive(:can_test?).and_return(false)

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
        let(:project) { create(:project) }

        context 'with chat notification service' do
          let(:service) { project.create_microsoft_teams_service(webhook: 'http://webhook.com') }

          it 'returns success' do
            allow_any_instance_of(MicrosoftTeams::Notifier).to receive(:ping).and_return(true)

            put :test, params: project_params

            expect(response).to be_successful
          end
        end

        it 'returns success' do
          stub_request(:get, 'http://example.com/rest/api/2/serverInfo')
            .to_return(status: 200, body: '{}')

          expect(Gitlab::HTTP).to receive(:get).with('/rest/api/2/serverInfo', any_args).and_call_original

          put :test, params: project_params(service: service_params)

          expect(response).to be_successful
        end
      end

      it 'returns success' do
        stub_request(:get, 'http://example.com/rest/api/2/serverInfo')
          .to_return(status: 200, body: '{}')

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
            'project_url' => 'http://test.com'
          }
        end

        before do
          allow_any_instance_of(ServiceHook).to receive(:execute).and_return(true)
        end

        it 'persist the object' do
          do_put

          expect(response).to be_successful
          expect(json_response).to be_empty
          expect(BuildkiteService.first).to be_present
        end

        it 'creates the ServiceHook object' do
          do_put

          expect(response).to be_successful
          expect(json_response).to be_empty
          expect(BuildkiteService.first.service_hook).to be_present
        end

        def do_put
          put :test, params: project_params(id: 'buildkite',
                                            service: service_params)
        end
      end
    end

    context 'failure' do
      it 'returns success status code and the error message' do
        stub_request(:get, 'http://example.com/rest/api/2/serverInfo')
          .to_return(status: 404)

        put :test, params: project_params(service: service_params)

        expect(response).to be_successful
        expect(json_response).to eq(
          'error' => true,
          'message' => 'Test failed.',
          'service_response' => '',
          'test_failed' => true
        )
      end
    end
  end

  describe 'PUT #update' do
    describe 'as HTML' do
      let(:service_params) { { active: true } }

      before do
        put :update, params: project_params(service: service_params)
      end

      context 'when param `active` is set to true' do
        it 'activates the service and redirects to integrations paths' do
          expect(response).to redirect_to(project_settings_integrations_path(project))
          expect(flash[:notice]).to eq 'Jira activated.'
        end
      end

      context 'when param `active` is set to false' do
        let(:service_params) { { active: false } }

        it 'does not activate the service but saves the settings' do
          expect(flash[:notice]).to eq 'Jira settings saved, but not activated.'
        end
      end

      context 'when activating Jira service from a template' do
        let(:service) do
          create(:jira_service, project: project, template: true)
        end

        it 'activate Jira service from template' do
          expect(flash[:notice]).to eq 'Jira activated.'
        end
      end
    end

    describe 'as JSON' do
      before do
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
  end

  describe 'GET #edit' do
    before do
      get :edit, params: project_params(id: 'jira')
    end

    context 'with approved services' do
      it 'renders edit page' do
        expect(response).to be_successful
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
