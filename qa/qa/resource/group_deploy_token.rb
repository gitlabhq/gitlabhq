# frozen_string_literal: true

module QA
  module Resource
    class GroupDeployToken < Base
      attr_accessor :name, :expires_at
      attr_writer :scopes

      attribute :id
      attribute :token
      attribute :username

      attribute :group do
        Group.fabricate! do |resource|
          resource.name = 'group-with-deploy-token'
          resource.description = 'group for adding deploy token test'
        end
      end

      def api_get_path
        "/groups/#{group.id}/deploy_tokens"
      end

      def api_post_path
        api_get_path
      end

      def api_post_body
        {
          name: @name,
          scopes: @scopes
        }
      end

      def api_delete_path
        "/groups/#{group.id}/deploy_tokens/#{id}"
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def fabricate!
        group.visit!

        Page::Group::Menu.perform(&:go_to_repository_settings)

        Page::Group::Settings::Repository.perform do |setting|
          setting.expand_deploy_tokens do |page|
            page.fill_token_name(name)
            page.fill_token_expires_at(expires_at)
            page.fill_scopes(@scopes)

            page.add_token
          end
        end
      end
    end
  end
end
