module QA
  module Factory
    module Resource
      class CiVariable < Factory::Base
        attr_accessor :key, :value

        attribute :project do
          Factory::Resource::Project.fabricate! do |resource|
            resource.name = 'project-with-ci-variables'
            resource.description = 'project for adding CI variable test'
          end
        end

        def fabricate!
          project.visit!

          Page::Project::Menu.perform(&:click_ci_cd_settings)

          Page::Project::Settings::CICD.perform do |setting|
            setting.expand_ci_variables do |page|
              page.fill_variable(key, value)

              page.save_variables
            end
          end
        end
      end
    end
  end
end
