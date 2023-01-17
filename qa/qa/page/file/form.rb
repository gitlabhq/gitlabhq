# frozen_string_literal: true

module QA
  module Page
    module File
      class Form < Page::Base
        include Page::Component::DropdownFilter
        include Page::Component::BlobContent
        include Shared::CommitMessage
        include Shared::CommitButton
        include Shared::Editor

        view 'app/views/projects/blob/_editor.html.haml' do
          element :file_name_field
        end

        view 'app/views/projects/blob/_template_selectors.html.haml' do
          element :gitignore_dropdown
          element :gitlab_ci_yml_dropdown
          element :dockerfile_dropdown
          element :license_dropdown
        end

        def add_name(name)
          fill_element(:file_name_field, name)
        end

        def add_custom_name(template_name)
          case template_name
          # Name has to be exactly LICENSE for template-type-dropdown to appear
          when 'LICENSE'
            add_name(template_name.to_s)
          else
            add_name("#{SecureRandom.hex(8)}/#{template_name}")
          end
        end

        def select_template(template_type, template)
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
