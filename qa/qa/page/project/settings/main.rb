# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Main < Page::Base
          include QA::Page::Settings::Common
          include Component::Select2
          include SubMenus::Project
          include Component::Breadcrumbs

          view 'app/views/projects/edit.html.haml' do
            element :advanced_settings_content
            element :merge_request_settings_content
            element :visibility_features_permissions_content
          end

          view 'app/views/projects/settings/_general.html.haml' do
            element :project_name_field
            element :save_naming_topics_avatar_button
          end

          def rename_project_to(name)
            fill_project_name(name)
            click_save_changes
          end

          def fill_project_name(name)
            fill_element :project_name_field, name
          end

          def click_save_changes
            click_element :save_naming_topics_avatar_button
          end

          def expand_advanced_settings(&block)
            expand_content(:advanced_settings_content) do
              Advanced.perform(&block)
            end
          end

          def expand_merge_requests_settings(&block)
            expand_content(:merge_request_settings_content) do
              MergeRequest.perform(&block)
            end
          end

          def expand_visibility_project_features_permissions(&block)
            expand_content(:visibility_features_permissions_content) do
              VisibilityFeaturesPermissions.perform(&block)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::Main.prepend_mod_with("Page::Project::Settings::Main", namespace: QA)
