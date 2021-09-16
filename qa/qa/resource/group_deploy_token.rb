# frozen_string_literal: true

module QA
  module Resource
    class GroupDeployToken < Base
      attr_accessor :name, :expires_at

      attribute :username do
        Page::Group::Settings::Repository.perform do |repository_page|
          repository_page.expand_deploy_tokens(&:token_username)
        end
      end

      attribute :password do
        Page::Group::Settings::Repository.perform do |repository_page|
          repository_page.expand_deploy_tokens(&:token_password)
        end
      end

      attribute :group do
        Group.fabricate! do |resource|
          resource.name = 'group-with-deploy-token'
          resource.description = 'group for adding deploy token test'
        end
      end

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-to-deploy'
          resource.description = 'project for adding deploy token test'
        end
      end

      def fabricate!
        group.visit!

        Page::Group::Menu.perform(&:go_to_repository_settings)

        Page::Group::Settings::Repository.perform do |setting|
          setting.expand_deploy_tokens do |page|
            page.fill_token_name(name)
            page.fill_token_expires_at(expires_at)
            page.fill_scopes(read_repository: true, read_package_registry: true, write_package_registry: true)

            page.add_token
          end
        end
      end
    end
  end
end
