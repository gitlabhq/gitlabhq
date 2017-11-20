module QA
  module EE
    module Page
      module Admin
        class GeoNodes < QA::Page::Base
          def set_node_address(address)
            fill_in 'URL', with: address
          end

          def add_node!
            click_button 'Add Node'
          end
        end
      end
    end
  end
end
