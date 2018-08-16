require 'spec_helper'

describe Projects::Settings::IntegrationsController do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  shared_examples 'endpoint with some disabled services' do
    it 'has some disabled services' do
      get :show, namespace_id: project.namespace, project_id: project

      expect(active_services).not_to include(*disabled_services)
    end
  end

  shared_examples 'endpoint without disabled services' do
    it 'does not have disabled services' do
      get :show, namespace_id: project.namespace, project_id: project

      expect(active_services).to include(*disabled_services)
    end
  end

  context 'Sets correct services list' do
    let(:active_services) { assigns(:services).map(&:type) }
    let(:disabled_services) { %w(JenkinsService JenkinsDeprecatedService) }

    it 'enables SlackSlashCommandsService and disables GitlabSlackApplication' do
      get :show, namespace_id: project.namespace, project_id: project

      expect(active_services).to include('SlackSlashCommandsService')
      expect(active_services).not_to include('GitlabSlackApplicationService')
    end

    it 'enables GitlabSlackApplication and disables SlackSlashCommandsService' do
      stub_application_setting(slack_app_enabled: true)
      allow(::Gitlab).to receive(:com?).and_return(true)

      get :show, namespace_id: project.namespace, project_id: project

      expect(active_services).to include('GitlabSlackApplicationService')
      expect(active_services).not_to include('SlackSlashCommandsService')
    end

    context 'without a license key' do
      before do
        License.destroy_all # rubocop: disable DestroyAll
      end

      it_behaves_like 'endpoint with some disabled services'
    end

    context 'with a license key' do
      let(:namespace) { create(:group, :private) }
      let(:project) { create(:project, :private, namespace: namespace) }

      context 'when checking of namespace plan is enabled' do
        before do
          allow(Gitlab::CurrentSettings.current_application_settings).to receive(:should_check_namespace_plan?) { true }
        end

        context 'and namespace does not have a plan' do
          it_behaves_like 'endpoint with some disabled services'
        end

        context 'and namespace has a plan' do
          let(:namespace) { create(:group, :private, plan: :bronze_plan) }

          it_behaves_like 'endpoint without disabled services'
        end
      end

      context 'when checking of namespace plan is not enabled' do
        before do
          allow(Gitlab::CurrentSettings.current_application_settings).to receive(:should_check_namespace_plan?) { false }
        end

        it_behaves_like 'endpoint without disabled services'
      end
    end
  end
end
