# frozen_string_literal: true

module QA
  module Flow
    module Project
      extend self

      def go_to_create_project_from_template
        Page::Project::New.perform(&:click_create_from_template_link)
      end

      def archive_project(project)
        project.visit!

        Page::Project::Menu.perform(&:go_to_general_settings)
        Page::Project::Settings::Main.perform(&:expand_advanced_settings)
        Page::Project::Settings::Advanced.perform(&:archive_project)
        Support::Waiter.wait_until do
          Page::Project::Show.perform { |show| show.has_text?("Archived project!") }
        end
      end

      def enable_catalog_resource_feature(project)
        project.visit!

        Page::Project::Menu.perform(&:go_to_general_settings)
        Page::Project::Settings::Main.perform do |settings|
          settings.expand_visibility_project_features_permissions(&:enable_ci_cd_catalog_resource)
        end
      end
    end
  end
end

QA::Flow::Project.prepend_mod_with('Flow::Project', namespace: QA)
