# frozen_string_literal: true

module QA
  module Resource
    class CiVariable < Base
      attr_accessor :key, :value

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-with-ci-variables'
          resource.description = 'project for adding CI variable test'
        end
      end

      def fabricate!
        project.visit!

        Page::Project::Menu.perform(&:go_to_ci_cd_settings)

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
