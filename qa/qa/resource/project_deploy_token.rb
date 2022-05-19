# frozen_string_literal: true

module QA
  module Resource
    class ProjectDeployToken < Base
      attr_accessor :name, :expires_at
      attr_writer :scopes

      attribute :id
      attribute :token
      attribute :username

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-to-deploy'
          resource.description = 'project for adding deploy token test'
        end
      end

      def api_get_path
        "/projects/#{project.id}/deploy_tokens"
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
        "/projects/#{project.id}/deploy_tokens/#{id}"
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def fabricate!
        project.visit!

        Page::Project::Menu.perform(&:go_to_repository_settings)

        Page::Project::Settings::Repository.perform do |setting|
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
