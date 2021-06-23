# frozen_string_literal: true

module QA
  module Page
    module Component
      module Import
        module Gitlab
          def self.included(base)
            super

            base.view 'app/views/import/gitlab_projects/new.html.haml' do
              element :import_project_button
            end

            base.view 'app/views/import/shared/_new_project_form.html.haml' do
              element :project_name_field
              element :project_slug_field
            end
          end

          def set_imported_project_name(name)
            fill_element(:project_name_field, name)
          end

          def attach_exported_file(path)
            page.attach_file("file", path, make_visible: { display: 'block' })
          end

          def click_import_gitlab_project
            click_element(:import_project_button)

            wait_until(reload: false) do
              has_notice?("The project was successfully imported.")
            end
          end
        end
      end
    end
  end
end
