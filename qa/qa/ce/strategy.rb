# frozen_string_literal: true

module QA
  module CE
    module Strategy
      class << self
        # Perform global setup
        #
        # @return [Boolean] returns true if hooks were performed successfully
        def perform_before_hooks
          log_browser_versions

          # Perform app readiness check before continuing with the whole test suite
          Tools::ReadinessCheck.perform(wait: 120)

          # Initialize global api admin client
          initialize_admin_api_client!
          # Initialize global test user and it's api client
          initialize_test_user!

          if Runtime::Env.rspec_retried?
            Runtime::Logger.info('Skipping further global hooks due to retry process')
            return false
          end

          if Runtime::Env.allow_local_requests?
            Runtime::ApplicationSettings.set_application_settings(
              allow_local_requests_from_web_hooks_and_services: true
            )
          end

          true
        end

        private

        def log_browser_versions
          Runtime::Logger.info("Using Browser: #{Runtime::Env.browser}")
          return unless Runtime::Env.use_selenoid?

          Runtime::Logger.info("Using Selenoid Browser version: #{Runtime::Env.selenoid_browser_version}")
        end

        def initialize_admin_api_client!
          Runtime::User::Store.initialize_admin_api_client
        rescue Runtime::User::ExpiredPasswordError
          # Reset admin password if admin token is present but can't be used due to expired password
          # Mostly issue with gdk where default seeded password for admin user will be expired
          Runtime::Logger.warn(
            "Admin password must be reset before the configured access token can be used. Setting password now..."
          )

          Runtime::Browser.visit(:gitlab, Page::Main::Login)
          admin_user = Runtime::User::Store.admin_user
          Page::Main::Login.perform do |login|
            login.sign_in_using_credentials(user: admin_user)
          rescue Runtime::User::ExpiredPasswordError
            login.set_up_new_password(user: admin_user)
          end

          Page::Main::Menu.perform(&:sign_out_if_signed_in)

          Runtime::User::Store.initialize_admin_api_client # re-initialize admin client after password reset
          admin_user.reload! # reload user attributes once admin client is initialized
        end

        # Initialize test user and it's api client before test execution for live environments
        #
        # @return [void]
        def initialize_test_user!
          return unless Runtime::Env.running_on_live_env?

          Runtime::User::Store.initialize_user_api_client
          Runtime::User::Store.initialize_test_user
        end
      end
    end
  end
end
