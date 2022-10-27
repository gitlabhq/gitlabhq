# frozen_string_literal: true

module QA
  module Page
    module Component
      module LazyLoader
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/layouts/_img_loader.html.haml' do
            element :js_lazy_loaded_content
          end
        end
      end
    end
  end
end
