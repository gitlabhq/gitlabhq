# frozen_string_literal: true

require 'date'

module QA
  module Resource
    class GroupAccessToken < Base
      attr_writer :name

      attribute :id
      attribute :group do
        Group.fabricate!
      end

      attribute :token do
        Page::Group::Settings::AccessTokens.perform(&:created_access_token)
      end

      def api_get_path
        "/groups/#{group.id}/access_tokens"
      end

      def api_post_path
        api_get_path
      end

      def name
        @name || 'api-group-access-token'
      end

      def api_post_body
        {
          name: name,
          scopes: ["api"]
        }
      end

      def api_delete_path
        "/groups/#{group.id}/access_tokens/#{id}"
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def revoke_via_ui!
        Page::Group::Settings::AccessTokens.perform do |tokens_page|
          tokens_page.revoke_first_token_with_name(name)
        end
      end

      def fabricate!
        Flow::Login.sign_in_unless_signed_in

        group.visit!

        Page::Group::Menu.perform(&:go_to_access_token_settings)

        Page::Group::Settings::AccessTokens.perform do |token_page|
          token_page.fill_token_name(name || 'api-project-access-token')
          token_page.check_api
          # Expire in 2 days just in case the token is created just before midnight
          token_page.fill_expiry_date(Time.now.utc.to_date + 2)
          token_page.click_create_token_button
        end
      end
    end
  end
end
