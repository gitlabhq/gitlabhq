module QA
  module Page
    module Admin
      class Menu < Page::Base
        def go_to_license
          click_link 'License'
        end

        def go_to_settings
          click_link 'Settings'
        end
      end
    end
  end
end
