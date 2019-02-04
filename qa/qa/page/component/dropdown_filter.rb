# frozen_string_literal: true

module QA
  module Page
    module Component
      module DropdownFilter
        def filter_and_select(item)
          wait(reload: false) do
            page.has_css?('.dropdown-input-field')
          end

          find('.dropdown-input-field').set(item)
          click_link item
        end
      end
    end
  end
end
