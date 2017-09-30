module QA
  module Page
    module Admin
      class Menu < Page::Base
        def go_to_license
          link = find_link 'License'
          # Click space to scroll this link into the view
          link.send_keys(:space)
          link.click
        end
      end
    end
  end
end
