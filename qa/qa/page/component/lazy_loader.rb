# frozen_string_literal: true

module QA
  module Page
    module Component
      module LazyLoader
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/lazy_loader.js' do
            element :js_lazy_loaded
          end
        end
      end
    end
  end
end
