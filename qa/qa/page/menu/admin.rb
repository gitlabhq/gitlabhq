module QA
  module Page
    module Menu
      class Admin < Page::Base
        def go_to_geo_nodes
          click_link 'Geo Nodes'
        end

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
