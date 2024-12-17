# frozen_string_literal: true

module QA
  module Resource
    class ImpersonationToken < Base
      attr_writer :name

      attribute :id
      attribute :user
      attribute :token
      attribute :expires_at

      def api_get_path
        "/users/#{user.id}/impersonation_tokens/#{id}"
      rescue NoValueError
        token = parse_body(api_get_from("/users/#{user.id}/impersonation_tokens")).find { |t| t[:name] == name }

        raise ResourceNotFoundError unless token

        @id = token[:id]
        retry
      end

      def api_post_path
        "/users/#{user.id}/impersonation_tokens"
      end

      def name
        @name ||= "api-impersonation-access-token-#{Faker::Alphanumeric.alphanumeric(number: 8)}"
      end

      def api_post_body
        {
          name: name,
          scopes: ["api"],
          expires_at: expires_at.to_s
        }
      end

      def api_delete_path
        "/users/#{user.id}/impersonation_tokens/#{id}"
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def revoke_via_browser_ui!
        Flow::Login.sign_in_unless_signed_in(user: Runtime::User::Store.admin_user)

        Page::Main::Menu.perform(&:go_to_admin_area)
        Page::Admin::Menu.perform(&:go_to_users_overview)
        Page::Admin::Overview::Users::Index.perform do |index|
          index.choose_search_user(user.username)
          index.click_search
          index.click_user(user.name)
        end

        Page::Admin::Overview::Users::Show.perform do |show|
          show.go_to_impersonation_tokens do |impersonation_tokens|
            impersonation_tokens.revoke_first_token_with_name(name)
          end
        end
        yield if block_given?
      end

      # Expire in 2 days just in case the token is created just before midnight
      def expires_at
        @expires_at || (Time.now.utc.to_date + 2)
      end

      def fabricate!
        Flow::Login.sign_in_unless_signed_in(user: Runtime::User::Store.admin_user)

        Page::Main::Menu.perform(&:go_to_admin_area)
        Page::Admin::Menu.perform(&:go_to_users_overview)
        Page::Admin::Overview::Users::Index.perform do |index|
          index.choose_search_user(user.username)
          index.click_search
          index.click_user(user.name)
        end

        Page::Admin::Overview::Users::Show.perform do |show|
          show.go_to_impersonation_tokens do |impersonation_tokens|
            impersonation_tokens.click_add_new_token_button
            impersonation_tokens.fill_token_name(name)
            impersonation_tokens.check_api
            impersonation_tokens.fill_expiry_date(expires_at)
            impersonation_tokens.click_create_token_button
            self.token = impersonation_tokens.created_access_token
          end
        end

        reload!
      end
    end
  end
end
