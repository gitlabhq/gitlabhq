# frozen_string_literal: true

module QA
  module Page
    module Project
      class New < Page::Base
        include Page::Component::Project::Templates
        include Page::Component::Select2
        include Page::Component::VisibilitySetting

        include Layout::Flash
        include Page::Component::Import::Selection
        include Page::Component::Import::Gitlab

        view 'app/views/projects/_new_project_fields.html.haml' do
          element :initialize_with_readme_checkbox
          element :project_namespace_select
          element :project_namespace_field, 'namespaces_options' # rubocop:disable QA/ElementWithPattern
          element :project_name, 'text_field :name' # rubocop:disable QA/ElementWithPattern
          element :project_path, 'text_field :path' # rubocop:disable QA/ElementWithPattern
          element :project_description, 'text_area :description' # rubocop:disable QA/ElementWithPattern
          element :project_create_button, "submit _('Create project')" # rubocop:disable QA/ElementWithPattern
          element :visibility_radios, 'visibility_level:' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/projects/project_templates/_template.html.haml' do
          element :use_template_button
          element :template_option_row
        end

        view 'app/assets/javascripts/vue_shared/new_namespace/components/welcome.vue' do
          element :panel_link
        end

        def click_blank_project_link
          click_element(:panel_link, panel_name: 'blank_project')
        end

        def click_create_from_template_link
          click_element(:panel_link, panel_name: 'create_from_template')
        end

        def choose_test_namespace
          choose_namespace(Runtime::Namespace.path)
        end

        def choose_namespace(namespace)
          retry_on_exception do
            click_element :project_namespace_select unless dropdown_open?
            search_and_select(namespace)
          end
        end

        def click_import_project
          click_on 'Import project'
        end

        def choose_name(name)
          fill_in 'project_name', with: name
        end

        def add_description(description)
          fill_in 'project_description', with: description
        end

        def create_new_project
          click_on 'Create project'
        end

        def click_create_from_template_tab
          click_element(:project_create_from_template_tab)
        end

        def set_visibility(visibility)
          choose visibility.capitalize
        end

        def click_github_link
          click_link 'GitHub'
        end

        def click_repo_by_url_link
          click_button 'Repo by URL'
        end

        def enable_initialize_with_readme
          check_element(:initialize_with_readme_checkbox)
        end
      end
    end
  end
end

QA::Page::Project::New.prepend_mod_with('Page::Project::New', namespace: QA)
