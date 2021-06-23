# frozen_string_literal: true

module QA
  module Page
    module Component
      module Import
        module Selection
          def self.included(base)
            super

            base.view 'app/views/projects/_import_project_pane.html.haml' do
              element :gitlab_import_button
            end
          end

          def click_gitlab
            click_element(:gitlab_import_button)
          end
        end
      end
    end
  end
end
