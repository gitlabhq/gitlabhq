module QA
  module EE
    module Page
      module Admin
        module Geo
          module Nodes
            class New < QA::Page::Base
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
  end
end
