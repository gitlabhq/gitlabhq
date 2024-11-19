# frozen_string_literal: true

module QA
  module Resource
    class InstanceOauthApplication < Base
      uses_admin_api_client

      attr_accessor :name, :redirect_uri, :scopes, :trusted

      attributes :id, :application_id, :application_secret

      def initialize
        @name = "Instance OAuth Application #{SecureRandom.hex(8)}"
        @redirect_uri = ''
        @scopes = []
        @trusted = true
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def api_get_path
        '/applications'
      end

      def api_delete_path
        "/applications/#{id}"
      end

      def fabricate!
        Flow::Login.sign_in_as_admin
        Page::Main::Menu.perform(&:go_to_admin_area)
        Page::Admin::Menu.perform(&:go_to_applications)
        Page::Admin::Applications.perform do |app|
          app.click_new_application_button
          app.fill_name(name)
          app.fill_redirect_uri(redirect_uri)
          app.set_trusted_checkbox(trusted)
          scopes.each { |scope| app.set_scope(scope) }
          app.save_application
          self.application_id = app.get_application_id
          self.application_secret = app.get_secret_id
          self.id = app.get_id_of_application
        end
      end
    end
  end
end
