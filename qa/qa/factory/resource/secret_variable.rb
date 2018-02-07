module QA
  module Factory
    module Resource
      class SecretVariable < Factory::Base
        attr_accessor :key, :value

        product :key do
          Page::Project::Settings::CICD.act do
            expand_secret_variables(&:variable_key)
          end
        end

        product :value do
          Page::Project::Settings::CICD.act do
            expand_secret_variables(&:variable_value)
          end
        end

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
