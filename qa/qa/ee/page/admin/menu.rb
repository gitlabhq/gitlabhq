# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Menu
          def self.prepended(page)
            page.module_eval do
              view 'app/views/layouts/nav/sidebar/_admin.html.haml' do
                element :license, "_('License')"
                element :geo_node, "_('Geo')"
              end
            end
          end

          def go_to_geo_nodes
            click_link 'Geo'
          end

          def go_to_license
            click_link 'License'
          end
        end
      end
    end
  end
end
