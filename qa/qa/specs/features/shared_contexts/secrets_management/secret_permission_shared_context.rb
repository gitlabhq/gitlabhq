# frozen_string_literal: true

module QA
  RSpec.shared_context 'secrets manager base' do
    include QA::EE::Support::Helpers::SecretsManagement::SecretsManagerHelper # rubocop: disable Cop/InjectEnterpriseEditionModule -- Helpers are added this way

    def owner
      @owner ||= create(:user)
    end

    def project
      @project ||= create(:project, :with_readme, name: 'secrets-manager-test-project')
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
      Support::Waiter.wait_until(max_duration: 10, sleep_interval: 1) do
        project.reload!
        project.find_member(owner.username).present?
      end

      # SM availability requires instance enrollment on self-managed.
      enroll_instance_in_secrets_manager

      # Provisioning happens from the Secrets page or the API, so provision
      # through GraphQL instead of driving the UI.
      provision_secrets_manager(project, token: owner.create_personal_access_token!.token)
    end
  end
end
