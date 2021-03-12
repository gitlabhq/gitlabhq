# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin, :skip_live_env do
    describe '2FA' do
      let(:owner_user) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_2fa_owner_username_1, Runtime::Env.gitlab_qa_2fa_owner_password_1)
      end

      let(:sandbox_group) do
        Resource::Sandbox.fabricate! do |sandbox_group|
          sandbox_group.path = "gitlab-qa-2fa-sandbox-group"
          sandbox_group.api_client = owner_api_client
        end
      end

      let(:group) do
        QA::Resource::Group.fabricate_via_api! do |group|
          group.sandbox = sandbox_group
          group.api_client = owner_api_client
          group.path = "group-with-2fa-#{SecureRandom.hex(8)}"
        end
      end

      let(:developer_user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = admin_api_client
        end
      end

      let(:two_fa_expected_text) { /The group settings for.*require you to enable Two-Factor Authentication for your account.*You need to do this before/ }

      before do
        Runtime::Feature.enable(:invite_members_group_modal, group: group)
        group.add_member(developer_user, Resource::Members::AccessLevel::DEVELOPER)
      end

      it 'allows enforcing 2FA via UI and logging in with 2FA', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/898' do
        enforce_two_factor_authentication_on_group(group)

        enable_two_factor_authentication_for_user(developer_user)

        Flow::Login.sign_in(as: developer_user, skip_page_validation: true)

        Page::Main::TwoFactorAuth.perform do |two_fa_auth|
          two_fa_auth.set_2fa_code('000000')
          two_fa_auth.click_verify_code_button
        end

        expect(page).to have_text('Invalid two-factor code')

        Page::Main::TwoFactorAuth.perform do |two_fa_auth|
          two_fa_auth.set_2fa_code(@otp.fresh_otp)
          two_fa_auth.click_verify_code_button
        end

        expect(Page::Main::Menu.perform(&:signed_in?)).to be_truthy
      end

      after do
        group.set_require_two_factor_authentication(value: 'false')
        group.remove_via_api! do |resource|
          resource.api_client = admin_api_client
        end
        developer_user.remove_via_api!
      end

      def admin_api_client
        @admin_api_client ||= Runtime::API::Client.as_admin
      end

      def owner_api_client
        @owner_api_client ||= Runtime::API::Client.new(:gitlab, user: owner_user)
      end

      # We are intentionally using the UI to enforce 2FA to exercise the flow with UI.
      # Any future tests should use the API for this purpose.
      def enforce_two_factor_authentication_on_group(group)
        Flow::Login.while_signed_in(as: owner_user) do
          group.visit!

          Page::Group::Menu.perform(&:click_group_general_settings_item)
          Page::Group::Settings::General.perform(&:set_require_2fa_enabled)

          expect(page).to have_text(two_fa_expected_text)

          Page::Profile::TwoFactorAuth.perform(&:click_configure_it_later_button)

          expect(page).not_to have_text(two_fa_expected_text)
        end
      end

      def enable_two_factor_authentication_for_user(user)
        Flow::Login.while_signed_in(as: user) do
          expect(page).to have_text(two_fa_expected_text)

          Page::Profile::TwoFactorAuth.perform do |two_fa_auth|
            @otp = QA::Support::OTP.new(two_fa_auth.otp_secret_content)

            two_fa_auth.set_pin_code(@otp.fresh_otp)
            two_fa_auth.click_register_2fa_app_button

            two_fa_auth.click_copy_and_proceed

            expect(two_fa_auth).to have_text('You have set up 2FA for your account!')
          end
        end
      end
    end
  end
end
