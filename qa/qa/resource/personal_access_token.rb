# frozen_string_literal: true

require 'date'

module QA
  module Resource
    class PersonalAccessToken < Base
      uses_admin_api_client

      attr_accessor :username, :password

      attributes :id, :user_id, :name, :active, :revoked, :scopes, :token

      attribute :expires_at do
        Time.now.utc.to_date + 2
      end

      attribute :name do
        "api-pat-#{Faker::Alphanumeric.alphanumeric(number: 8)}"
      end

      def fabricate_via_api!
        raise Runtime::User::InvalidTokenError, "Admin api client is missing" unless api_client

        super
        self.api_client = Runtime::API::Client.new(personal_access_token: token)
      rescue Runtime::User::InvalidTokenError, NoValueError
        # fabricate via UI if admin token is not present or not valid or user_id is not set
        fabricate!
      end

      def fabricate!
        user = User.init do |usr|
          usr.username = username || raise("username is required for personal access token fabrication via UI")
          usr.password = password || raise("password is required for personal access token fabrication via UI")
        end

        already_signed_in = Page::Main::Menu.perform do |menu|
          menu.signed_in_as_user?(user)
        end

        Flow::Login.sign_in(as: user) unless already_signed_in

        Page::Main::Menu.perform(&:click_edit_profile_link)
        Page::Profile::Menu.perform(&:click_access_tokens)

        Page::Profile::PersonalAccessTokens.perform do |token_page|
          token_page.click_add_new_token_button
          token_page.fill_token_name(name)
          token_page.check_api
          token_page.fill_expiry_date(expires_at)
          token_page.click_create_token_button

          self.token = Page::Profile::PersonalAccessTokens.perform(&:created_access_token)
          self.api_client = Runtime::API::Client.new(personal_access_token: token)
          self.id = parse_body(api_get_from("/personal_access_tokens", q_params: { search: name })).first[:id]
        end

        # keep the user signed in if they were already signed in when fabrication was performed
        Page::Main::Menu.perform(&:sign_out) unless already_signed_in

        reload!
      end

      def api_post_path
        "/users/#{user_id}/personal_access_tokens"
      end

      def api_get_path
        "/personal_access_tokens/#{id}"
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

      # Return token value when implicitly converting this object to string
      #
      # @return [String]
      def to_s
        token
      end
    end
  end
end
