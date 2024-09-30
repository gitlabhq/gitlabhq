# frozen_string_literal: true

module QA
  module CE
    module Strategy
      class << self
        # Perform global setup
        #
        # @return [Boolean] returns true if hooks were performed successfully
        def perform_before_hooks
          cache_tokens!
          log_browser_versions

          if Runtime::Env.rspec_retried?
            Runtime::Logger.info('Skipping global hooks due to retry process')
            return false
          end

          # Perform app readiness check before continuing with the whole test suite
          Tools::ReadinessCheck.perform(wait: 60)

          # Reset admin password if admin token is present but can't be used due to expired password
          reset_admin_password!

          if Runtime::Env.allow_local_requests?
            Runtime::ApplicationSettings.set_application_settings(
              allow_local_requests_from_web_hooks_and_services: true
            )
          end

          true
        end

        private

        def cache_tokens!
          if Runtime::Env.admin_personal_access_token.present?
            Resource::PersonalAccessTokenCache.set_token_for_username(
              Runtime::User.admin_username,
              Runtime::Env.admin_personal_access_token
            )
          end

          return unless Runtime::Env.personal_access_token.present? && Runtime::Env.user_username.present?

          Resource::PersonalAccessTokenCache.set_token_for_username(
            Runtime::Env.user_username,
            Runtime::Env.personal_access_token
          )
        end

        def log_browser_versions
          Runtime::Logger.info("Using Browser: #{Runtime::Env.browser}")
          return unless Runtime::Env.use_selenoid?

          Runtime::Logger.info("Using Selenoid Browser version: #{Runtime::Env.selenoid_browser_version}")
        end

        def reset_admin_password!
          return unless Runtime::Env.admin_personal_access_token.present?

          response = Support::API.get(Runtime::API::Request.new(Runtime::API::Client.as_admin, "/user").url)
          return unless response.code == 403 && response.body.include?("Your password expired")

          # Mostly issue with gdk where default seeded password for admin user will be expired
          Runtime::Logger.warn(
            "Admin password must be reset before the configured access token can be used. Setting password now..."
          )

          Runtime::Browser.visit(:gitlab, Page::Main::Login)
          Page::Main::Login.perform(&:sign_in_using_admin_credentials)
          Page::Main::Login.perform(&:set_up_new_admin_password_if_required)
          Page::Main::Menu.perform(&:sign_out_if_signed_in)
        end
      end
    end
  end
end
