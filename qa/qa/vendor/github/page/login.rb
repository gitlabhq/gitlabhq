# frozen_string_literal: true

module QA
  module Vendor
    module Github
      module Page
        class Login < Vendor::Page::Base
          def login
            QA::Runtime::Logger.info("Signing into Github...")

            fill_in 'login', with: QA::Runtime::Env.github_username
            fill_in 'password', with: QA::Runtime::Env.github_password
            click_on 'Sign in'

            enter_otp_with_retry

            authorize_app

            confirm_account_recovery_settings
          end

          # GitHub immediately auto-redirects after inputting the correct OTP code
          #
          # This action is a flakiness buffer in case it doesn't.
          def verify_otp
            click_on 'Verify' if has_button?('Verify')
          end

          def authorize_app
            click_on 'Authorize' if has_button?('Authorize')
          end

          def confirm_account_recovery_settings
            click_on 'Confirm' if has_button?('Confirm')
          end

          def enter_otp_with_retry
            return QA::Runtime::Logger.info("GitHub 2FA page did not load.") unless has_field?('app_otp')

            current_otp = OnePassword::CLI.instance.current_otp
            fill_in_github_otp(current_otp, "Filled in GitHub OTP")
            return QA::Runtime::Logger.info("GitHub OTP succeeded.") unless has_field?('app_otp')

            # If the OTP is stale, try again with a new one
            new_otp = OnePassword::CLI.instance.new_otp(current_otp)
            fill_in_github_otp(new_otp, "Retry filling in GitHub OTP")
            return QA::Runtime::Logger.info("GitHub OTP succeeded after retrying.") unless has_field?('app_otp')

            QA::Runtime::Logger.error("GitHub OTP failed.")
          end

          def fill_in_github_otp(otp, message)
            QA::Runtime::Logger.info(message)

            fill_in 'app_otp', with: otp

            verify_otp
          end
        end
      end
    end
  end
end
