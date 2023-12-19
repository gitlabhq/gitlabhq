# frozen_string_literal: true

module QA
  module Page
    module Project
      module Tag
        class Index < Page::Base
          view 'app/views/projects/tags/index.html.haml' do
            element 'new-tag-button'
          end

          def click_new_tag_button
            click_element('new-tag-button')
          end
        end
      end
    end
  end
end
