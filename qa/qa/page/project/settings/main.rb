# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Main < Page::Base
          include QA::Page::Settings::Common
          include Component::Breadcrumbs
          include Layout::Flash

          view 'app/views/projects/edit.html.haml' do
            element 'advanced-settings-content'
            element 'visibility-features-permissions-content'
            element 'badges-settings-content'
          end

          view 'app/views/projects/settings/merge_requests/show.html.haml' do
            element 'merge-request-settings-content'
          end

          view 'app/views/projects/settings/_general.html.haml' do
            element 'project-name-field'
            element 'save-naming-topics-avatar-button'
          end

          def rename_project_to(name)
            fill_project_name(name)
            click_save_changes
          end

          def fill_project_name(name)
            fill_element 'project-name-field', name
          end

          def click_save_changes
            click_element 'save-naming-topics-avatar-button'
          end

          def download_export_started?
            has_text?('Project export started')
          end

          def expand_advanced_settings(&block)
            expand_content('advanced-settings-content') do
              Advanced.perform(&block)
            end
          end

          def expand_visibility_project_features_permissions(&block)
            expand_content('visibility-features-permissions-content') do
              VisibilityFeaturesPermissions.perform(&block)
            end
          end

          def expand_badges_settings(&block)
            expand_content('badges-settings-content') do
              Component::Badges.perform(&block)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::Main.prepend_mod_with("Page::Project::Settings::Main", namespace: QA)
