# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class VisibilityFeaturesPermissions < Page::Base
          view 'app/assets/javascripts/pages/projects/shared/permissions/components/settings_panel.vue' do
            element :project_visibility_dropdown
            element :visibility_features_permissions_save_button
          end

          def set_project_visibility(visibility)
            select_element(:project_visibility_dropdown, visibility)
            click_element :visibility_features_permissions_save_button
          end
        end
      end
    end
  end
end
