module QA
  module Page
    module Admin
      class Menu < Page::Base
        def go_to_license
          within_middle_menu { click_link 'License' }
        end

        private

        def within_middle_menu
          page.within('.nav-control') do
            yield
          end
        end
      end
    end
  end
end
