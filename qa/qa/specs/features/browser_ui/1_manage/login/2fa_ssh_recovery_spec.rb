# frozen_string_literal: true

module QA
  context 'Manage', :requires_admin, :skip_live_env do
    describe '2FA' do
      let!(:user) { Resource::User.fabricate_via_api! }
      let!(:user_api_client) { Runtime::API::Client.new(:gitlab, user: user) }
      let(:address) { QA::Runtime::Scenario.gitlab_address }
      let(:uri) { URI.parse(address) }
      let(:ssh_port) { uri.port == 80 ? '' : '2222' }
      let!(:ssh_key) do
        Resource::SSHKey.fabricate_via_api! do |resource|
          resource.title = "key for ssh tests #{Time.now.to_f}"
          resource.api_client = user_api_client
        end
      end

      before do
        enable_2fa_for_user(user)
      end

      it 'allows 2FA code recovery via ssh' do
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
          Page::Main::Menu.perform(&:click_settings_link)
          Page::Profile::Menu.perform(&:click_account)
          Page::Profile::Accounts::Show.perform(&:click_enable_2fa_button)

          Page::Profile::TwoFactorAuth.perform do |two_fa_auth|
            otp = QA::Support::OTP.new(two_fa_auth.otp_secret_content)
            two_fa_auth.set_pin_code(otp.fresh_otp)
            two_fa_auth.click_register_2fa_app_button
            two_fa_auth.click_proceed_button
          end
        end
      end
    end
  end
end
