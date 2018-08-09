module QA
  module Page
    module Project
      class New < Page::Base
        include Page::Component::Select2

        view 'app/views/projects/new.html.haml' do
          element :import_project_tab, "Import project"
        end

        view 'app/views/projects/_new_project_fields.html.haml' do
          element :project_namespace_select
          element :project_namespace_field, 'namespaces_options'
          element :project_path, 'text_field :path'
          element :project_description, 'text_area :description'
          element :project_create_button, "submit 'Create project'"
          element :visibility_radios, 'visibility_level:'
        end

        view 'app/views/projects/_import_project_pane.html.haml' do
          element :import_github, "icon('github', text: 'GitHub')"
        end

        def choose_test_namespace
          click_element :project_namespace_select

          select_item(Runtime::Namespace.path)
        end

        def go_to_import_project
          click_on 'Import project'
        end

        def choose_name(name)
          fill_in 'project_path', with: name
        end

        def add_description(description)
          fill_in 'project_description', with: description
        end

        def create_new_project
          click_on 'Create project'
        end

        def set_visibility(visibility)
          choose visibility
        end

        def go_to_github_import
          click_link 'GitHub'
        end
      end
    end
  end
end
