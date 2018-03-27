module QA
  module Factory
    module Resource
      class SecretVariable < Factory::Base
        attr_accessor :key, :value

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-with-secret-variables'
          project.description = 'project for adding secret variable test'
        end

        def fabricate!
          project.visit!

          Page::Menu::Side.act { click_ci_cd_settings }

          Page::Project::Settings::CICD.perform do |setting|
            setting.expand_secret_variables do |page|
              page.fill_variable_key(key)
              page.fill_variable_value(value)

              page.save_variables
            end
          end
        end
      end
    end
  end
end
