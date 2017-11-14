module QA
  module Page
    module Main
      class OAuth < Page::Base
        def authorize
          click_button 'Authorize'
        end
      end
    end
  end
end
