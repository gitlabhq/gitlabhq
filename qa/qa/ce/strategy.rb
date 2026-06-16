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
          Tools::ReadinessCheck.perform(wait: 180)

          # Initialize global api admin client
          initialize_admin_api_client!
          # Initialize global test user and it's api client
          initialize_test_user!
          # Ensure at least one group exists before any admin signs in via the UI
          ensure_initial_group_exists!

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
            Support::Retrier.retry_until(retry_on_exception: true, message: "set_up_new_password failed") do
              # Visit the homepage to be re-routed to the new password page if CSRF token authenticity error shown
              if login.has_text?("Can't verify CSRF token authenticity", wait: 0)
                login.visit Runtime::Scenario.gitlab_address
                login.sign_in_using_credentials(user: admin_user)
              end

              login.set_up_new_password(user: admin_user)
            end
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

        # Pre-create the e2e sandbox group via the API so that at least one group exists
        # before any admin signs in through the UI.
        #
        # On a fresh self-managed instance with no groups, admin sign-in is redirected to the
        # welcome onboarding flow (/admin/registrations/...), which renders the minimal layout
        # without the super sidebar and breaks Page::Main::Menu validation. The redirect is
        # gated on `!Group.exists?` (a system-wide check), so creating any group here disables
        # it for the whole run. Doing it via the API also avoids the first lazy Sandbox
        # fabrication taking the UI path and hitting the same redirect.
        # See app/controllers/sessions_controller.rb#should_redirect_to_sm_onboarding?
        #
        # @return [void]
        def ensure_initial_group_exists!
          # Live environments already have groups and use SaaS onboarding, which is not affected.
          return if Runtime::Env.running_on_live_env?
          # Requires an admin client; without one the redirect can't be pre-empted here.
          return unless Runtime::User::Store.admin_api_client

          Resource::Sandbox.fabricate_via_api! do |sandbox|
            sandbox.api_client = Runtime::User::Store.admin_api_client
          end
        rescue StandardError => e
          Runtime::Logger.warn(
            "Failed to pre-create sandbox group: #{e.message}. Admin welcome onboarding redirect may occur."
          )
        end
      end
    end
  end
end
