# frozen_string_literal: true

module QA
  module Page
    module Component
      module Breadcrumbs
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/layouts/nav/breadcrumbs/_breadcrumbs.html.haml' do
            element 'breadcrumb-links'
          end
        end

        def has_breadcrumb?(text)
          # In some situations the length of the breadcrumbs may lead to it being condensed. For these situations
          # open the dropdown toggle which should allow us to see the all components of the breadcrumb.
          if has_no_element?('breadcrumb-links', text: text, wait: 0)
            within_element('breadcrumb-links') { click_element('base-dropdown-toggle') }
          end

          has_element?('breadcrumb-links', text: text)
        end
      end
    end
  end
end
