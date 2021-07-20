# frozen_string_literal: true

require 'date'

module QA
  module Resource
    class PersonalAccessToken < Base
      attr_accessor :name

      # The user for which the personal access token is to be created
      # This *could* be different than the api_client.user or the api_user provided by the QA::Resource::ApiFabricator module
      attr_writer :user

      attribute :token

      # Only Admins can create PAT via the API.
      # If Runtime::Env.admin_personal_access_token is provided, fabricate via the API,
      # else, fabricate via the browser.
      def fabricate_via_api!
        @token = QA::Resource::PersonalAccessTokenCache.get_token_for_username(user.username)
        return if @token

        resource = if Runtime::Env.admin_personal_access_token && !@user.nil?
                     self.api_client = Runtime::API::Client.as_admin

                     super
                   else
                     fabricate!
                   end

        QA::Resource::PersonalAccessTokenCache.set_token_for_username(user.username, self.token)
        resource
      end

      # When a user is not provided, use default user
      def user
        @user || Resource::User.default
      end

      def api_post_path
        "/users/#{user.api_resource[:id]}/personal_access_tokens"
      end

      def api_get_path
        '/personal_access_tokens'
      end

      def api_post_body
        {
          name: name || 'api-test-token',
          scopes: ["api"]
        }
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def fabricate!
        Flow::Login.sign_in_unless_signed_in(as: user)

        Page::Main::Menu.perform(&:click_edit_profile_link)
        Page::Profile::Menu.perform(&:click_access_tokens)

        Page::Profile::PersonalAccessTokens.perform do |token_page|
          token_page.fill_token_name(name || 'api-test-token')
          token_page.check_api
          # Expire in 2 days just in case the token is created just before midnight
          token_page.fill_expiry_date(Time.now.utc.to_date + 2)
          token_page.click_create_token_button

          self.token = Page::Profile::PersonalAccessTokens.perform(&:created_access_token)
        end
      end
    end
  end
end
