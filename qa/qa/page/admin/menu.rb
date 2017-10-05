module QA
  module Page
    module Admin
      class Menu < Page::Base
        def go_to_license
          link = find_link 'License'
          link.click
        end
      end
    end
  end
end
