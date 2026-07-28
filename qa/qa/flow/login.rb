# frozen_string_literal: true

module QA
  module Flow
    module Login
      extend self

      def while_signed_in(as: nil, address: :gitlab, admin: false)
        sign_in(as: as, address: address, admin: admin)

        result = yield

        Page::Main::Menu.perform(&:sign_out)
        result
      end

      def while_signed_in_as_admin(address: :gitlab, &block)
        while_signed_in(address: address, admin: true, &block)
      end

      def sign_in(as: nil, address: :gitlab, skip_page_validation: false, admin: false, raise_on_invalid_login: true)
        Page::Main::Login.perform do |login|
          login.redirect_to_login_page(address)

          if admin
            login.sign_in_using_admin_credentials
          else
            login.sign_in_using_credentials(
              user: as,
              skip_page_validation: skip_page_validation,
              raise_on_invalid_login: raise_on_invalid_login
            )
          end
        end
      end

      def sign_in_as_admin(address: :gitlab)
        sign_in(as: Runtime::User::Store.admin_user, address: address, admin: true)
      end

      def sign_in_unless_signed_in(user: nil, address: :gitlab)
        if user
          sign_in(as: user, address: address) unless Page::Main::Menu.perform do |menu|
            menu.signed_in_as_user?(user)
          end
        else
          sign_in(address: address) unless Page::Main::Menu.perform(&:signed_in?)
        end
      end

      # Submits a 2FA code from the challenge page. Callers assert the outcome
      # with a waiting matcher (has_personal_area? on success, have_text on
      # failure), which rides through the post-login redirect rather than
      # racing it as a one-shot signed_in? would.
      def submit_2fa_code(code)
        Page::Main::TwoFactorAuth.perform do |two_fa_auth|
          two_fa_auth.set_2fa_code(code)
          two_fa_auth.click_verify_code_button
        end
      end
    end
  end
end

QA::Flow::Login.prepend_mod_with('Flow::Login', namespace: QA)
