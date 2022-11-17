# frozen_string_literal: true

module QA
  module Mobile
    module Page
      module Base
        prepend Support::Page::Logging

        def fill_element(name, content)
          # We need to bypass click_element_cooridinates as it does not work on mobile devices
          find_element(name).set(content)
        end
      end
    end
  end
end
