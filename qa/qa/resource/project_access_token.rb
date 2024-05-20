# frozen_string_literal: true

require 'date'

module QA
  module Resource
    class ProjectAccessToken < Base
      attr_writer :name

      attribute :id
      attribute :user_id
      attribute :expires_at
      attribute :token

      attribute :project do
        Project.fabricate!
      end

      def api_get_path
        "/projects/#{project.id}/access_tokens/#{id}"
      rescue NoValueError
        token = parse_body(api_get_from("/projects/#{project.id}/access_tokens")).find { |t| t[:name] == name }

        raise ResourceNotFoundError unless token

        @id = token[:id]
        retry
      end

      def identifier
        "with name '#{name}', token's bot username '#{token_user[:username]}'"
      end

      def api_post_path
        "/projects/#{project.id}/access_tokens"
      end

      def api_user_path
        "/users/#{user_id}"
      end

      def token_user
        parse_body(api_get_from(api_user_path))
      end

      def name
        @name ||= "api-project-access-token-#{Faker::Alphanumeric.alphanumeric(number: 8)}"
      end

      def api_post_body
        {
          name: name,
          scopes: ["api"],
          expires_at: expires_at.to_s
        }
      end

      def api_delete_path
        "projects/#{project.api_resource[:id]}/access_tokens/#{id}"
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def revoke_via_ui!
        Page::Project::Settings::AccessTokens.perform do |tokens_page|
          tokens_page.revoke_first_token_with_name(name)
        end
      end

      # Expire in 2 days just in case the token is created just before midnight
      def expires_at
        @expires_at || (Time.now.utc.to_date + 2)
      end

      def fabricate!
        Flow::Login.sign_in_unless_signed_in

        project.visit!

        Page::Project::Menu.perform(&:go_to_access_token_settings)

        Page::Project::Settings::AccessTokens.perform do |token_page|
          token_page.click_add_new_token_button
          token_page.fill_token_name(name)
          token_page.check_api
          token_page.fill_expiry_date(expires_at)
          token_page.click_create_token_button
          self.token = token_page.created_access_token
        end

        reload!
      end
    end
  end
end
