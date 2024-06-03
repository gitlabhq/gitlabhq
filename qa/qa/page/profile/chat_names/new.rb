# frozen_string_literal: true

module QA
  module Page
    module Profile
      module ChatNames
        class New < Page::Base
          view 'app/views/profiles/chat_names/new.html.haml' do
            element 'authorize-button'
          end

          def authorize
            click_element('authorize-button')
          end
        end
      end
    end
  end
end
