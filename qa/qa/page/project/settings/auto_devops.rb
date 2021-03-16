# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class AutoDevops < Page::Base
          view 'app/views/projects/settings/ci_cd/_autodevops_form.html.haml' do
            element :enable_autodevops_checkbox
            element :save_changes_button
          end

          def enable_autodevops
            check_element(:enable_autodevops_checkbox)
            click_element(:save_changes_button)
          end
        end
      end
    end
  end
end
