# frozen_string_literal: true

module QA
  module Page
    module Main
      class OAuth < Page::Base
        view 'app/views/doorkeeper/authorizations/new.html.haml' do
          element 'authorization-button'
        end

        def needs_authorization?
          page.current_url.include?('/oauth')
        end

        def authorize!
          click_element 'authorization-button'
        end
      end
    end
  end
end
