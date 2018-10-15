module QA
  module Factory
    module Resource
      class DeployToken < Factory::Base
        attr_accessor :name, :expires_at

        product :username do |resource|
          Page::Project::Settings::Repository.act do
            expand_deploy_tokens do |token|
              token.token_username
            end
          end
        end

        product :password do |password|
          Page::Project::Settings::Repository.act do
            expand_deploy_tokens do |token|
              token.token_password
            end
          end
        end

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-to-deploy'
          project.description = 'project for adding deploy token test'
        end

        def fabricate!
          project.visit!

          Page::Project::Menu.act do
            click_repository_settings
          end

          Page::Project::Settings::Repository.perform do |setting|
            setting.expand_deploy_tokens do |page|
              page.fill_token_name(name)
              page.fill_token_expires_at(expires_at)
              page.fill_scopes(read_repository: true, read_registry: false)

              page.add_token
            end
          end
        end
      end
    end
  end
end
