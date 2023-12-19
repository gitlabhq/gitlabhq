# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class AutoDevops < Page::Base
          view 'app/views/projects/settings/ci_cd/_autodevops_form.html.haml' do
            element 'enable-autodevops-checkbox'
            element 'save-changes-button'
          end

          def enable_autodevops
            check_element('enable-autodevops-checkbox')
            click_element('save-changes-button')
          end
        end
      end
    end
  end
end
