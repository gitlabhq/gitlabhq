module QA
  module Page
    module Main
      class OAuth < Page::Base
        def needs_authorization?
          page.current_url.include?('/oauth')
        end

        def authorize!
          click_button 'Authorize'
        end
      end
    end
  end
end
