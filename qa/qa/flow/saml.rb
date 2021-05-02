# frozen_string_literal: true

module QA
  module Flow
    module Saml
      module_function

      def page
        Capybara.current_session
      end

      def logout_from_idp(saml_idp_service)
        Runtime::Logger.debug("Logging out of IDP by visiting \"#{saml_idp_service.idp_sign_out_url}\"")

        Support::Waiter.wait_until(sleep_interval: 1, reload_page: page) do
          page.visit saml_idp_service.idp_sign_out_url
          page.has_content?("You have been logged out.")
        end
      end

      def enable_saml_sso(group, saml_idp_service, enforce_sso: false, default_membership_role: 'Guest')
        Runtime::Feature.enable(:group_administration_nav_item)

        page.visit Runtime::Scenario.gitlab_address

        Page::Main::Login.perform(&:sign_in_using_credentials) unless Page::Main::Menu.perform(&:signed_in?)

        visit_saml_sso_settings(group)

        Support::Retrier.retry_on_exception do
          EE::Page::Group::Settings::SamlSSO.perform do |saml_sso|
            saml_sso.enforce_sso if enforce_sso
            saml_sso.set_id_provider_sso_url(saml_idp_service.idp_sso_url)
            saml_sso.set_cert_fingerprint(saml_idp_service.idp_certificate_fingerprint)
            saml_sso.set_default_membership_role(default_membership_role)
            saml_sso.click_save_changes

            saml_sso.user_login_url_link_text
          end
        end
      end

      def visit_saml_sso_settings(group, direct: false)
        if direct
          url = "#{group.web_url}/-/saml"
          Runtime::Logger.debug("Visiting url \"#{url}\" directly")
          page.visit url
        else
          group.visit!

          Page::Group::Menu.perform(&:go_to_saml_sso_group_settings)
        end
        # The toggle buttons take a moment to switch to the correct status.
        # I am not sure of a better, less complex way to wait for them to reflect their actual status.
        sleep 2
      end

      def run_saml_idp_service(group_name)
        Service::DockerRun::SamlIdp.new(Runtime::Scenario.gitlab_address, group_name).tap do |runner|
          runner.pull
          runner.register!
        end
      end

      def remove_saml_idp_service(saml_idp_service)
        saml_idp_service.remove!
      end

      def login_to_idp_if_required(username, password)
        Vendor::SAMLIdp::Page::Login.perform { |login_page| login_page.login_if_required(username, password) }
      end
    end
  end
end
