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
          has_element?('breadcrumb-links', text: text)
        end
      end
    end
  end
end
