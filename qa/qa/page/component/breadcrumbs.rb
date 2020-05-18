# frozen_string_literal: true

module QA
  module Page
    module Component
      module Breadcrumbs
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/layouts/nav/_breadcrumbs.html.haml' do
            element :breadcrumb_links_content
          end
        end

        def has_breadcrumb?(text)
          has_element?(:breadcrumb_links_content, text: text)
        end
      end
    end
  end
end
