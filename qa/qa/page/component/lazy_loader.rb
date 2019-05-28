# frozen_string_literal: true

module QA
  module Page
    module Component
      module LazyLoader
        def self.included(base)
          base.view 'app/assets/javascripts/lazy_loader.js' do
            element :js_lazy_loaded
          end
        end
      end
    end
  end
end
