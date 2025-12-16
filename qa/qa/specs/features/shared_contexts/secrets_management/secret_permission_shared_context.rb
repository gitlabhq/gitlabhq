# frozen_string_literal: true

module QA
  RSpec.shared_context 'secrets manager base' do
    include QA::EE::Support::Helpers::SecretsManagement::SecretsManagerHelper # rubocop: disable Cop/InjectEnterpriseEditionModule -- Helpers are added this way

    def owner
      @owner ||= create(:user)
    end

    def project
      @project ||= create(:project, :with_readme, name: 'secrets-manager-test-project',
        api_client: Runtime::User::Store.admin_api_client)
    end

    before(:context) do
      project.add_member(owner, Resource::Members::AccessLevel::OWNER)
      enable_secrets_manager
    end

    after(:context) do
      deprovision_secrets_manager(project)
    end

    private

    def enable_secrets_manager
      Flow::Login.sign_in(as: owner)
      skip "OpenBao instance is not reachable" unless openbao_healthy?
      project.visit!

      Page::Project::Menu.perform(&:go_to_general_settings)
      Page::Project::Settings::Main.perform do |settings|
        settings.expand_visibility_project_features_permissions do |permissions|
          permissions.enable_secrets_manager
          Support::Waiter.wait_until(max_duration: 60, sleep_interval: 2) do
            permissions.secrets_manager_enabled?
          end
        end
      end
    end
  end
end
