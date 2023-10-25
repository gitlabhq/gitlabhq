# frozen_string_literal: true

module QA
  module Page
    module Component
      module Import
        module Selection
          def self.included(base)
            super

            base.view 'app/views/projects/_import_project_pane.html.haml' do
              element 'gitlab-import-button'
            end
          end

          def click_gitlab
            retry_until(reload: true, max_attempts: 10, message: 'Waiting for import source to be enabled') do
              has_element?('gitlab-import-button')
            end

            click_element('gitlab-import-button')
          end
        end
      end
    end
  end
end
