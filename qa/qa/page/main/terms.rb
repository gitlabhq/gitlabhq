# frozen_string_literal: true

module QA
  module Page
    module Main
      class Terms < Page::Base
        view 'app/views/layouts/terms.html.haml' do
          element :user_avatar, required: true
        end

        view 'app/views/users/terms/index.html.haml' do
          element :terms_content, required: true

          element :accept_terms_button
        end

        def accept_terms
          click_element :accept_terms_button, Page::Main::Menu
        end
      end
    end
  end
end
