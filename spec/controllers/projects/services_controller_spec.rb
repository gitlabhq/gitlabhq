require 'spec_helper'

describe Projects::ServicesController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }
  let(:service) { create(:hipchat_service, project: project) }
  let(:hipchat_client) { { '#room' => double(send: true) } }
  let(:service_params) { { token: 'hipchat_token_p', room: '#room' } }

  before do
    sign_in(user)
    project.team << [user, :master]

    controller.instance_variable_set(:@project, project)
    controller.instance_variable_set(:@service, service)
  end

  describe '#test' do
    context 'when can_test? returns false' do
      it 'renders 404' do
        allow_any_instance_of(Service).to receive(:can_test?).and_return(false)

        put :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id

        expect(response).to have_http_status(404)
      end
    end

    context 'success' do
      context 'with empty project' do
        let(:project) { create(:empty_project) }

        context 'with chat notification service' do
          let(:service) { project.create_microsoft_teams_service(webhook: 'http://webhook.com') }

          it 'returns success' do
            allow_any_instance_of(MicrosoftTeams::Notifier).to receive(:ping).and_return(true)

            put :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id

            expect(response.status).to eq(200)
          end
        end

        it 'returns success' do
          expect(HipChat::Client).to receive(:new).with('hipchat_token_p', anything).and_return(hipchat_client)

          put :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id, service: service_params

          expect(response.status).to eq(200)
        end
      end

      it 'returns success' do
        expect(HipChat::Client).to receive(:new).with('hipchat_token_p', anything).and_return(hipchat_client)

        put :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id, service: service_params

        expect(response.status).to eq(200)
      end
    end

    context 'failure' do
      it 'returns success status code and the error message' do
        expect(HipChat::Client).to receive(:new).with('hipchat_token_p', anything).and_raise('Bad test')

        put :test, namespace_id: project.namespace.id, project_id: project.id, id: service.id, service: service_params

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
          namespace_id: project.namespace.id, project_id: project.id, id: service.id, service: { active: true }

        expect(response).to redirect_to(project_settings_integrations_path(project))
        expect(flash[:notice]).to eq 'HipChat activated.'
      end
    end

    context 'when param `active` is set to false' do
      it 'does not  activate the service but saves the settings' do
        put :update,
          namespace_id: project.namespace.id, project_id: project.id, id: service.id, service: { active: false }

        expect(flash[:notice]).to eq 'HipChat settings saved, but not activated.'
      end
    end
  end
end
