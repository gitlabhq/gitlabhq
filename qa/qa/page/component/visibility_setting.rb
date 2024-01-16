# frozen_string_literal: true

module QA
  module Page
    module Component
      module VisibilitySetting
        extend QA::Page::PageConcern

        def set_visibility(visibility)
          find('label', text: visibility.capitalize).click
        end
      end
    end
  end
end
