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

        put :test, params: { namespace_id: project.namespace, project_id: project, id: service.to_param }

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when validations fail' do
      let(:service_params) { { active: 'true', url: '' } }

      it 'returns error messages in JSON response' do
        put :test, params: { namespace_id: project.namespace, project_id: project, id: service.to_param, service: service_params }

        expect(json_response['message']).to eq "Validations failed."
        expect(json_response['service_response']).to include "Url can't be blank"
        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'success' do
      context 'with empty project' do
        let(:project) { create(:project) }

        context 'with chat notification service' do
          let(:service) { project.create_microsoft_teams_service(webhook: 'http://webhook.com') }

          it 'returns success' do
            allow_any_instance_of(MicrosoftTeams::Notifier).to receive(:ping).and_return(true)

            put :test, params: { namespace_id: project.namespace, project_id: project, id: service.to_param }

            expect(response.status).to eq(200)
          end
        end

        it 'returns success' do
          stub_request(:get, 'http://example.com/rest/api/2/serverInfo')
            .to_return(status: 200, body: '{}')

          expect(Gitlab::HTTP).to receive(:get).with("/rest/api/2/serverInfo", any_args).and_call_original

          put :test, params: { namespace_id: project.namespace, project_id: project, id: service.to_param, service: service_params }

          expect(response.status).to eq(200)
        end
      end

      it 'returns success' do
        stub_request(:get, 'http://example.com/rest/api/2/serverInfo')
          .to_return(status: 200, body: '{}')

        expect(Gitlab::HTTP).to receive(:get).with("/rest/api/2/serverInfo", any_args).and_call_original

        put :test, params: { namespace_id: project.namespace, project_id: project, id: service.to_param, service: service_params }

        expect(response.status).to eq(200)
      end

      context 'when service is configured for the first time' do
        before do
          allow_any_instance_of(ServiceHook).to receive(:execute).and_return(true)
        end

        it 'persist the object' do
          do_put

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_empty
          expect(BuildkiteService.first).to be_present
        end

        it 'creates the ServiceHook object' do
          do_put

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_empty
          expect(BuildkiteService.first.service_hook).to be_present
        end

        def do_put
          put :test, params: {
                       namespace_id: project.namespace,
                       project_id: project,
                       id: 'buildkite',
                       service: { 'active' => '1', 'push_events' => '1', token: 'token', 'project_url' => 'http://test.com' }
                     }
        end
      end
    end

    context 'failure' do
      it 'returns success status code and the error message' do
        stub_request(:get, 'http://example.com/rest/api/2/serverInfo')
          .to_return(status: 404)

        put :test, params: { namespace_id: project.namespace, project_id: project, id: service.to_param, service: service_params }

        expect(response).to have_gitlab_http_status(200)
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
    context 'when param `active` is set to true' do
      it 'activates the service and redirects to integrations paths' do
        put :update,
          params: { namespace_id: project.namespace, project_id: project, id: service.to_param, service: { active: true } }

        expect(response).to redirect_to(project_settings_integrations_path(project))
        expect(flash[:notice]).to eq 'Jira activated.'
      end
    end

    context 'when param `active` is set to false' do
      it 'does not  activate the service but saves the settings' do
        put :update,
          params: { namespace_id: project.namespace, project_id: project, id: service.to_param, service: { active: false } }

        expect(flash[:notice]).to eq 'Jira settings saved, but not activated.'
      end
    end

    context 'when activating Jira service from a template' do
      let(:template_service) { create(:jira_service, project: project, template: true) }

      it 'activate Jira service from template' do
        put :update, params: { namespace_id: project.namespace, project_id: project, id: service.to_param, service: { active: true } }

        expect(flash[:notice]).to eq 'Jira activated.'
      end
    end
  end

  describe "GET #edit" do
    before do
      get :edit, params: { namespace_id: project.namespace, project_id: project, id: 'jira' }
    end

    context 'with approved services' do
      it 'renders edit page' do
        expect(response).to be_success
      end
    end
  end
end
