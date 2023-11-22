# frozen_string_literal: true

module QA
  module Page
    module Main
      class Terms < Page::Base
        view 'app/views/layouts/terms.html.haml' do
          element 'user-avatar-content', required: true
        end

        view 'app/assets/javascripts/terms/components/app.vue' do
          element 'terms-content', required: true

          element 'accept-terms-button'
        end

        def accept_terms
          click_element 'accept-terms-button', Page::Main::Menu
        end
      end
    end
  end
end
