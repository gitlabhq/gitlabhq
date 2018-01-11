module QA
  module EE
    module Page
      module Admin
        module Geo
          module Nodes
            class Show < QA::Page::Base
              view 'ee/app/views/admin/geo_nodes/index.html.haml' do
                element :new_node_link, /link_to .*New node/
              end

              def new_node!
                click_link 'New node'
              end
            end
          end
        end
      end
    end
  end
end
