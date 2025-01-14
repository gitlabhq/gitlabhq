# frozen_string_literal: true

module QA
  module Page
    module File
      class Form < Page::Base
        include Page::Component::ListboxFilter
        include Page::Component::BlobContent
        include Shared::CommitMessage
        include Shared::Editor

        view 'app/views/projects/blob/_editor.html.haml' do
          element 'file-name-field'
        end

        view 'app/assets/javascripts/blob/filepath_form/components/template_selector.vue' do
          element 'template-selector'
        end

        def add_name(name)
          fill_element('file-name-field', name)
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
          when '.gitignore', '.gitlab-ci.yml', 'Dockerfile', 'LICENSE'
            click_element 'template-selector'
          else
            raise %(Unsupported template_type "#{template_type}". Please confirm that it is a valid option.)
          end
          filter_and_select template
        end
      end
    end
  end
end
