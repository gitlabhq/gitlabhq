# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :requires_admin, product_group: :authentication do
    describe '2FA' do
      let!(:owner_user) { create(:user, :with_personal_access_token, username: "owner_user_#{SecureRandom.hex(4)}") }
      let!(:owner_api_client) { owner_user.api_client }

      let(:sandbox_group) do
        Flow::Login.sign_in(as: owner_user)
        Resource::Sandbox.fabricate! do |sandbox_group|
          sandbox_group.path = "gitlab-qa-2fa-sandbox-group-#{SecureRandom.hex(8)}"
          sandbox_group.api_client = owner_api_client
        end
      end

      let(:group) do
        create(:group, sandbox: sandbox_group, api_client: owner_api_client,
          path: "group-with-2fa-#{SecureRandom.hex(8)}")
      end

      let(:developer_user) do
        create(:user, username: "developer_user_#{SecureRandom.hex(4)}")
      end

      let(:two_fa_expected_text) do
        /The group settings for.*require you to enable Two-Factor Authentication for your account.*You need to do this/
      end

      before do
        group.add_member(developer_user, Resource::Members::AccessLevel::DEVELOPER)
      end

      it(
        'allows enforcing 2FA via UI and logging in with 2FA',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347931'
      ) do
        enforce_two_factor_authentication_on_group(group)

        otp = enable_two_factor_authentication_for_user(developer_user)

        Flow::Login.sign_in(as: developer_user, skip_page_validation: true)

        Page::Main::TwoFactorAuth.perform do |two_fa_auth|
          two_fa_auth.set_2fa_code('000000')
          two_fa_auth.click_verify_code_button
        end

        expect(page).to have_text('Invalid two-factor code')

        Page::Main::TwoFactorAuth.perform do |two_fa_auth|
          two_fa_auth.set_2fa_code(otp.fresh_otp)
          two_fa_auth.click_verify_code_button
        end

        expect(Page::Main::Menu.perform(&:signed_in?)).to be_truthy
      end

      # We are intentionally using the UI to enforce 2FA to exercise the flow with UI.
      # Any future tests should use the API for this purpose.
      def enforce_two_factor_authentication_on_group(group)
        Flow::Login.while_signed_in(as: owner_user) do
          group.visit!

          Page::Group::Menu.perform(&:go_to_general_settings)
          Page::Group::Settings::General.perform(&:set_require_2fa_enabled)

          QA::Support::Retrier.retry_on_exception(reload_page: page) do
            expect(page).to have_text(two_fa_expected_text)
          end

          Page::Profile::TwoFactorAuth.perform(&:click_configure_it_later_button)

          expect(page).not_to have_text(two_fa_expected_text)
        end
      end

      def enable_two_factor_authentication_for_user(user)
        Flow::Login.while_signed_in(as: user) do
          expect(page).to have_text(two_fa_expected_text)

          Page::Profile::TwoFactorAuth.perform do |two_fa_auth|
            otp = QA::Support::OTP.new(two_fa_auth.otp_secret_content)

            two_fa_auth.set_pin_code(otp.fresh_otp)
            two_fa_auth.set_current_password(user.password)
            two_fa_auth.click_register_2fa_app_button

            two_fa_auth.click_copy_and_proceed

            expect(two_fa_auth).to have_text('You have set up 2FA for your account!')

            otp
          end
        end
      end
    end
  end
end
