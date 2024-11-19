# frozen_string_literal: true

module QA
  module Page
    module Project
      class New < Page::Base
        include Page::Component::Project::Templates
        include Page::Component::VisibilitySetting
        include QA::Page::Component::Dropdown

        include Layout::Flash
        include Page::Component::Import::Selection
        include Page::Component::Import::Gitlab

        view 'app/views/projects/_new_project_fields.html.haml' do
          element 'initialize-with-readme-checkbox'
          element 'initialize-with-sast-checkbox'
          element 'project-name'
          element 'project-path'
          element 'project-description'
          element 'project-create-button'
          element 'visibility-radios'
        end

        view 'app/views/projects/project_templates/_template.html.haml' do
          element 'use-template-button'
          element 'template-option-container'
        end

        view 'app/assets/javascripts/projects/new/components/new_project_url_select.vue' do
          element 'select-namespace-dropdown'
        end

        view 'app/assets/javascripts/vue_shared/new_namespace/components/welcome.vue' do
          element 'panel-link'
        end

        def click_blank_project_link
          click_element('panel-link', panel_name: 'blank_project')
        end

        def click_create_from_template_link
          click_element('panel-link', panel_name: 'create_from_template')
        end

        def choose_namespace(namespace)
          # User not belonging to any groups will have pre-filled personal namespace path
          return unless has_element?('select-namespace-dropdown')
          # The current group is the default, we use end_with? in case we want to select the top level group
          return if find_element('select-namespace-dropdown').text.end_with?(namespace)

          click_element 'select-namespace-dropdown'
          fill_element '.gl-listbox-search-input', namespace
          select_item(namespace, css: '.gl-new-dropdown-item')
        end

        def click_import_project
          click_on 'Import project'
        end

        def choose_name(name)
          fill_in 'project_name', with: name
        end

        def add_description(description)
          return unless has_element?('project-description', wait: 1)

          fill_in 'project_description', with: description
        end

        def create_new_project
          click_on 'Create project'
        end

        def click_create_from_template_tab
          click_element(:project_create_from_template_tab)
        end

        def set_visibility(visibility)
          find('label', text: visibility.capitalize).click
        end

        # Disable experiment for SAST at project creation https://gitlab.com/gitlab-org/gitlab/-/issues/333196
        def disable_initialize_with_sast
          return unless has_element?('initialize-with-sast-checkbox', visible: false)

          uncheck_element('initialize-with-sast-checkbox', true)
        end

        def click_github_link
          retry_until(reload: true, max_attempts: 10, message: 'Waiting for import source to be enabled') do
            click_link 'GitHub'
          end
        end

        def click_repo_by_url_link
          retry_until(reload: true, max_attempts: 10, message: 'Waiting for import source to be enabled') do
            click_button 'Repository by URL'
          end
        end

        def disable_initialize_with_readme
          uncheck_element('initialize-with-readme-checkbox', true)
        end
      end
    end
  end
end

QA::Page::Project::New.prepend_mod_with('Page::Project::New', namespace: QA)
