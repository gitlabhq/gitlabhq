module QA
  module Page
    module Project
      module Settings
        class Advanced < Page::Base
          view 'app/views/projects/edit.html.haml' do
            element :project_path_field, 'f.text_field :path'
            element :project_name_field, 'f.text_field :name'
            element :rename_project_button, "f.submit 'Rename project'"
          end

          def rename_to(path)
            fill_project_name(path)
            fill_project_path(path)
            rename_project!
          end

          def fill_project_path(path)
            fill_in :project_path, with: path
          end

          def fill_project_name(name)
            fill_in :project_name, with: name
          end

          def rename_project!
            click_on 'Rename project'
          end
        end
      end
    end
  end
end
