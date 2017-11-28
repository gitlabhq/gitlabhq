module QA
  module Page
    module Project
      class Menu < Page::Base
        def branches
          find('a', text: /\ABranch/).click
        end

        def go_to_settings
          click_link 'Settings'
        end
      end
    end
  end
end
