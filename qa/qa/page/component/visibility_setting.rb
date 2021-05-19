# frozen_string_literal: true

module QA
  module Page
    module Component
      module VisibilitySetting
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/shared/_visibility_radios.html.haml' do
            element :visibility_radio, 'qa_selector: "#{visibility_level_label(level).downcase}_radio"' # rubocop:disable QA/ElementWithPattern, Lint/InterpolationCheck
          end
        end

        def set_visibility(visibility)
          choose_element("#{visibility.downcase}_radio", false, true)
        end
      end
    end
  end
end
