# frozen_string_literal: true

module QA
  module EE
    module Page
      module Menu
        module Admin
          def self.prepended(page)
            page.module_eval do
              view 'app/views/layouts/nav/sidebar/_admin.html.haml' do
                element :link_license_menu
                element :link_geo_menu
              end
            end
          end

          def go_to_geo_nodes
            click_element :link_geo_menu
          end

          def go_to_license
            click_element :link_license_menu
          end
        end
      end
    end
  end
end
