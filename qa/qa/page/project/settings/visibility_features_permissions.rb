# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class VisibilityFeaturesPermissions < Page::Base
          view 'app/assets/javascripts/pages/projects/shared/permissions/components/settings_panel.vue' do
            element 'project-visibility-dropdown'
            element 'project-features-save-button'
          end

          def set_project_visibility(visibility)
            select_element('project-visibility-dropdown', visibility)
            click_element 'project-features-save-button'
          end
        end
      end
    end
  end
end
