# frozen_string_literal: true

module QA
  RSpec.shared_context 'group secrets manager base' do
    include QA::EE::Support::Helpers::SecretsManagement::SecretsManagerHelper # rubocop: disable Cop/InjectEnterpriseEditionModule -- Helpers are added this way

    def owner
      @owner ||= create(:user)
    end

    def group
      @group ||= create(:group)
    end

    before(:context) do
      group.add_member(owner, Resource::Members::AccessLevel::OWNER)
      enable_group_secrets_manager
    end

    after(:context) do
      deprovision_secrets_manager(group)
    end

    private

    def enable_group_secrets_manager
      Support::Waiter.wait_until(max_duration: 10, sleep_interval: 1) do
        group.reload!
        group.find_member(owner.username).present?
      end

      # SM availability requires instance enrollment on self-managed.
      enroll_instance_in_secrets_manager

      # Provisioning happens from the Secrets page or the API, so provision
      # through GraphQL instead of driving the UI.
      provision_secrets_manager(group, token: owner.create_personal_access_token!.token)
    end
  end
end
