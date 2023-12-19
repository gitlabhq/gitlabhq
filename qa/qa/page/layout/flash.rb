# frozen_string_literal: true

module QA
  module Page
    module Layout
      module Flash
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/layouts/_flash.html.haml' do
            element 'flash-container'
          end
        end

        def has_notice?(message)
          within_element('flash-container') do
            has_text?(message)
          end
        end
      end
    end
  end
end
