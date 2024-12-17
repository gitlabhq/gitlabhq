# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :requires_admin, :skip_live_env,
    product_group: :authentication do
    describe '2FA' do
      let!(:user) { Runtime::User::Store.test_user }
      let!(:user_api_client) { user.api_client }
      let(:address) { QA::Runtime::Scenario.gitlab_address }
      let(:uri) { URI.parse(address) }
      let(:ssh_port) { uri.port == 80 ? '' : '2222' }
      let!(:ssh_key) { create(:ssh_key, title: "key for ssh tests #{Time.now.to_f}", api_client: user_api_client) }

      before do
        enable_2fa_for_user(user)
      end

      it 'allows 2FA code recovery via ssh',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347938' do
        recovery_code = Support::SSH.perform do |ssh|
          ssh.key = ssh_key
          ssh.uri = address.gsub(/(?<=:)(#{uri.port})/, ssh_port)
          ssh.setup
          output = ssh.reset_2fa_codes
          output.scan(/([A-Za-z0-9]{16})\n/).flatten.first
        end

        Flow::Login.sign_in(as: user, skip_page_validation: true)
        Page::Main::TwoFactorAuth.perform do |two_fa_auth|
          two_fa_auth.set_2fa_code(recovery_code)
          two_fa_auth.click_verify_code_button
        end

        expect(Page::Main::Menu.perform(&:signed_in?)).to be_truthy

        Page::Main::Menu.perform(&:sign_out)
        Flow::Login.sign_in(as: user, skip_page_validation: true)
        Page::Main::TwoFactorAuth.perform do |two_fa_auth|
          two_fa_auth.set_2fa_code(recovery_code)
          two_fa_auth.click_verify_code_button
        end

        expect(page).to have_text('Invalid two-factor code')
      end

      def enable_2fa_for_user(user)
        Flow::Login.while_signed_in(as: user) do
          Page::Main::Menu.perform(&:click_edit_profile_link)
          Page::Profile::Menu.perform(&:click_account)
          Page::Profile::Accounts::Show.perform(&:click_enable_2fa_button)

          Page::Profile::TwoFactorAuth.perform do |two_fa_auth|
            otp = QA::Support::OTP.new(two_fa_auth.otp_secret_content)
            two_fa_auth.set_pin_code(otp.fresh_otp)
            two_fa_auth.set_current_password(user.password)
            two_fa_auth.click_register_2fa_app_button
            two_fa_auth.click_copy_and_proceed
          end
        end
      end
    end
  end
end
