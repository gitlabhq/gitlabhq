require 'spec_helper'

describe Projects::ServicesController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }
  let(:service) { create(:hipchat_service, project: project) }
  let(:hipchat_client) { { '#room' => double(send: true) } }
  let(:service_params) { { token: 'hipchat_token_p', room: '#room' } }

  before do
    sign_in(user)
    project.add_master(user)
  end

  describe '#test' do
    context 'when can_test? returns false' do
      it 'renders 404' do
        allow_any_instance_of(Service).to receive(:can_test?).and_return(false)

        put :test, namespace_id: project.namespace, project_id: project, id: service.to_param

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when validations fail' do
      let(:service_params) { { active: 'true', token: '' } }

      it 'returns error messages in JSON response' do
        put :test, namespace_id: project.namespace, project_id: project, id: :hipchat, service: service_params

        expect(json_response['message']).to eq "Validations failed."
        expect(json_response['service_response']).to eq "Token can't be blank"
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

            put :test, namespace_id: project.namespace, project_id: project, id: service.to_param

            expect(response.status).to eq(200)
          end
        end

        it 'returns success' do
          expect(HipChat::Client).to receive(:new).with('hipchat_token_p', anything).and_return(hipchat_client)

          put :test, namespace_id: project.namespace, project_id: project, id: service.to_param, service: service_params

          expect(response.status).to eq(200)
        end
      end

      it 'returns success' do
        expect(HipChat::Client).to receive(:new).with('hipchat_token_p', anything).and_return(hipchat_client)

        put :test, namespace_id: project.namespace, project_id: project, id: service.to_param, service: service_params

        expect(response.status).to eq(200)
      end

      context 'when service is configured for the first time' do
        before do
          allow_any_instance_of(ServiceHook).to receive(:execute).and_return(true)
        end

        it 'persist the object' do
          do_put

          expect(BuildkiteService.first).to be_present
        end

        it 'creates the ServiceHook object' do
          do_put

          expect(BuildkiteService.first.service_hook).to be_present
        end

        def do_put
          put :test, namespace_id: project.namespace,
                     project_id: project,
                     id: 'buildkite',
                     service: { 'active' => '1', 'push_events' => '1', token: 'token', 'project_url' => 'http://test.com' }
        end
      end
    end

    context 'failure' do
      it 'returns success status code and the error message' do
        expect(HipChat::Client).to receive(:new).with('hipchat_token_p', anything).and_raise('Bad test')

        put :test, namespace_id: project.namespace, project_id: project, id: service.to_param, service: service_params

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body))
          .to eq('error' => true, 'message' => 'Test failed.', 'service_response' => 'Bad test')
      end
    end
  end

  describe 'PUT #update' do
    context 'when param `active` is set to true' do
      it 'activates the service and redirects to integrations paths' do
        put :update,
          namespace_id: project.namespace, project_id: project, id: service.to_param, service: { active: true }

        expect(response).to redirect_to(project_settings_integrations_path(project))
        expect(flash[:notice]).to eq 'HipChat activated.'
      end
    end

    context 'when param `active` is set to false' do
      it 'does not  activate the service but saves the settings' do
        put :update,
          namespace_id: project.namespace, project_id: project, id: service.to_param, service: { active: false }

        expect(flash[:notice]).to eq 'HipChat settings saved, but not activated.'
      end
    end

    context 'with a deprecated service' do
      let(:service) { create(:kubernetes_service, project: project) }

      before do
        put :update,
          namespace_id: project.namespace, project_id: project, id: service.to_param, service: { namespace: 'updated_namespace' }
      end

      it 'should not update the service' do
        service.reload
        expect(service.namespace).not_to eq('updated_namespace')
      end
    end
  end

  describe "GET #edit" do
    before do
      get :edit, namespace_id: project.namespace, project_id: project, id: service_id
    end

    context 'with approved services' do
      let(:service_id) { 'jira' }

      it 'should render edit page' do
        expect(response).to be_success
      end
    end

    context 'with a deprecated service' do
      let(:service_id) { 'kubernetes' }

      it 'should render edit page' do
        expect(response).to be_success
      end
    end
  end
end
