# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :requires_admin, :skip_live_env, :reliable do
    describe '2FA', product_group: :authentication do
      let(:owner_user) { create(:user, api_client: admin_api_client) }

      let(:developer_user) { create(:user, api_client: admin_api_client) }

      let(:sandbox_group) do
        Resource::Sandbox.fabricate! do |sandbox_group|
          sandbox_group.path = "gitlab-qa-2fa-recovery-sandbox-group-#{SecureRandom.hex(4)}"
          sandbox_group.api_client = owner_api_client
        end
      end

      let(:group) do
        create(:group, :require_2fa, sandbox: sandbox_group, api_client: owner_api_client)
      end

      before do
        group.add_member(developer_user, Resource::Members::AccessLevel::DEVELOPER)
      end

      it(
        'allows using 2FA recovery code once only',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347937'
      ) do
        recovery_code = enable_2fa_for_user_and_fetch_recovery_code(developer_user)

        Flow::Login.sign_in(as: developer_user, skip_page_validation: true)

        Page::Main::TwoFactorAuth.perform do |two_fa_auth|
          two_fa_auth.set_2fa_code(recovery_code)
          two_fa_auth.click_verify_code_button
        end

        expect(Page::Main::Menu.perform(&:signed_in?)).to be_truthy

        Page::Main::Menu.perform(&:sign_out)

        Flow::Login.sign_in(as: developer_user, skip_page_validation: true)

        Page::Main::TwoFactorAuth.perform do |two_fa_auth|
          two_fa_auth.set_2fa_code(recovery_code)
          two_fa_auth.click_verify_code_button
        end

        expect(page).to have_text('Invalid two-factor code')
      end

      def admin_api_client
        @admin_api_client ||= Runtime::API::Client.as_admin
      end

      def owner_api_client
        @owner_api_client ||= Runtime::API::Client.new(:gitlab, user: owner_user)
      end

      def enable_2fa_for_user_and_fetch_recovery_code(user)
        Flow::Login.while_signed_in(as: user) do
          Page::Profile::TwoFactorAuth.perform do |two_fa_auth|
            otp = QA::Support::OTP.new(two_fa_auth.otp_secret_content)

            two_fa_auth.set_pin_code(otp.fresh_otp)
            two_fa_auth.set_current_password(user.password)
            two_fa_auth.click_register_2fa_app_button

            recovery_code = two_fa_auth.recovery_codes.sample

            two_fa_auth.click_copy_and_proceed

            recovery_code
          end
        end
      end
    end
  end
end
