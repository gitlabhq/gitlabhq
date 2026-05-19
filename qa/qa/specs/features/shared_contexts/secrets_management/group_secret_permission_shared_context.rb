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

      # SM availability now requires (FF AND enrollment). Enroll the instance
      # so the SM section renders in group settings.
      enroll_instance_in_secrets_manager

      Flow::Login.while_signed_in(as: owner) do
        skip "OpenBao instance is not reachable" unless openbao_healthy?
        group.visit!

        Page::Group::Menu.perform(&:go_to_general_settings)
        Page::Group::Settings::General.perform do |settings|
          settings.enable_secrets_manager
          Support::Waiter.wait_until(max_duration: 60, sleep_interval: 2) do
            settings.has_secrets_manager_enabled?
          end
        end
      end
    end
  end
end
