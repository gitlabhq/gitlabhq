# frozen_string_literal: true

require 'date'

module QA
  module Resource
    class PersonalAccessToken < Base
      attr_writer :name

      # The user for which the personal access token is to be created
      # This *could* be different than the api_client.user or the api_user provided by the QA::Resource::ApiFabricator
      attr_writer :user

      attributes :id, :token

      attribute :expires_at do
        Time.now.utc.to_date + 2
      end

      # Only Admins can create PAT via the API.
      # If Runtime::Env.admin_personal_access_token is provided, fabricate via the API,
      # else, fabricate via the browser.
      def fabricate_via_api!
        return if find_and_set_value

        resource = if Runtime::Env.admin_personal_access_token && !@user.nil?
                     self.api_client = Runtime::API::Client.as_admin
                     super
                   else
                     fabricate!
                   end

        self.token = api_response[:token] unless api_response.nil?
        cache_token
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
        "/personal_access_tokens/#{id}"
      rescue NoValueError
        user.reload! unless user.id

        api_client = Runtime::API::Client.new(:gitlab,
          is_new_session: false,
          user: user,
          personal_access_token: token)
        request_url = Runtime::API::Request.new(api_client,
          "/personal_access_tokens?user_id=#{user.id}",
          per_page: '100').url

        token = auto_paginated_response(request_url).find { |t| t[:name] == name }

        raise ResourceNotFoundError unless token

        @id = token[:id]
        retry
      end

      def name
        @name ||= "api-pat-#{user.username}-#{Faker::Alphanumeric.alphanumeric(number: 8)}"
      end

      def api_post_body
        {
          name: name,
          scopes: ["api"],
          expires_at: expires_at.to_s
        }
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def find_and_set_value
        @token ||= QA::Resource::PersonalAccessTokenCache.get_token_for_username(user.username)
        @retrieved_from_cache = true if @token

        @token
      end

      def cache_token
        QA::Resource::PersonalAccessTokenCache.set_token_for_username(user.username, token) if @user && token
      end

      def fabricate!
        return if find_and_set_value

        Flow::Login.sign_in_unless_signed_in(user: user)

        Page::Main::Menu.perform(&:click_edit_profile_link)
        Page::Profile::Menu.perform(&:click_access_tokens)

        Page::Profile::PersonalAccessTokens.perform do |token_page|
          token_page.click_add_new_token_button
          token_page.fill_token_name(name || 'api-test-token')
          token_page.check_api
          token_page.fill_expiry_date(expires_at)
          token_page.click_create_token_button

          self.token = Page::Profile::PersonalAccessTokens.perform(&:created_access_token)

          cache_token

          token
        end
      end
    end
  end
end
