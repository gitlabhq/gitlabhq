# frozen_string_literal: true

module QA
  module Page
    module File
      class Form < Page::Base
        include Shared::CommitMessage
        include Page::Component::DropdownFilter
        include Shared::CommitButton
        include Shared::Editor

        view 'app/views/projects/blob/_editor.html.haml' do
          element :file_name, "text_field_tag 'file_name'" # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/projects/blob/_template_selectors.html.haml' do
          element :template_type_dropdown
          element :gitignore_dropdown
          element :gitlab_ci_yml_dropdown
          element :dockerfile_dropdown
          element :license_dropdown
        end

        def add_name(name)
          fill_in 'file_name', with: name
        end

        def select_template(template_type, template)
          click_element :template_type_dropdown
          click_link template_type

          case template_type
          when '.gitignore'
            click_element :gitignore_dropdown
          when '.gitlab-ci.yml'
            click_element :gitlab_ci_yml_dropdown
          when 'Dockerfile'
            click_element :dockerfile_dropdown
          when 'LICENSE'
            click_element :license_dropdown
          else
            raise %Q(Unsupported template_type "#{template_type}". Please confirm that it is a valid option.)
          end
          filter_and_select template
        end
      end
    end
  end
end
