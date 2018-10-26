module QA
  module Factory
    module Resource
      class SecretVariable < Factory::Base
        attr_accessor :key, :value

        attribute :project do
          Factory::Resource::Project.fabricate! do |resource|
            resource.name = 'project-with-secret-variables'
            resource.description = 'project for adding secret variable test'
          end
        end

        def fabricate!
          project.visit!

          Page::Project::Menu.perform(&:click_ci_cd_settings)

          Page::Project::Settings::CICD.perform do |setting|
            setting.expand_secret_variables do |page|
              page.fill_variable(key, value)

              page.save_variables
            end
          end
        end
      end
    end
  end
end
