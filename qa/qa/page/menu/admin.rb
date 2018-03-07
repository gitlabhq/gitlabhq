module QA
  module Page
    module Menu
      class Admin < Page::Base
        view 'app/views/layouts/nav/sidebar/_admin.html.haml' do
          element :settings, "_('Settings')"
        end

        def go_to_settings
          click_link 'Settings'
        end
      end
    end
  end
end
