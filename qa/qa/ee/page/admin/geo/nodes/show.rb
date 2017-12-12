module QA
  module EE
    module Page
      module Admin
        module Geo
          module Nodes
            class Show < QA::Page::Base
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
