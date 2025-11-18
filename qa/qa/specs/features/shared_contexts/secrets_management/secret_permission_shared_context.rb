# frozen_string_literal: true

module QA
  RSpec.shared_context 'secrets manager setup' do
    include QA::EE::Support::Helpers::SecretsManagement::SecretsManagerHelper # rubocop: disable Cop/InjectEnterpriseEditionModule -- Helpers are added this way

    def owner
      @owner ||= create(:user)
    end

    def project
      @project ||= create(:project, :with_readme, name: 'secrets-manager-test-project',
        api_client: Runtime::User::Store.admin_api_client)
    end

    def maintainer
      @maintainer ||= create(:user)
    end

    def reporter
      @reporter ||= create(:user)
    end

    def non_project_user
      @non_project_user ||= create(:user)
    end

    def non_project_owner
      @non_project_owner ||= create(:user)
    end

    def other_project
      @other_project ||= create(:project, :with_readme, name: 'other-project-for-testing',
        api_client: Runtime::User::Store.admin_api_client)
    end

    def sandbox_group
      @sandbox_group ||= create(:sandbox, api_client: Runtime::User::Store.admin_api_client)
    end

    def group
      @group ||= create(:group, sandbox: sandbox_group, api_client: Runtime::User::Store.admin_api_client)
    end

    before(:context) do
      setup_project_memberships
      enable_secrets_manager
    end

    after(:context) do
      deprovision_secrets_manager(project)
      other_project&.remove_via_api!
    end

    private

    def setup_project_memberships
      project.add_member(owner, Resource::Members::AccessLevel::OWNER)
      project.add_member(maintainer, Resource::Members::AccessLevel::MAINTAINER)
      project.add_member(reporter, Resource::Members::AccessLevel::REPORTER)
      other_project.add_member(non_project_owner, Resource::Members::AccessLevel::OWNER)
      project.invite_group(group, Resource::Members::AccessLevel::DEVELOPER)
    end

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
