module QA
  ##
  # GitLab EE extensions
  #
  module EE
    module Page
      module Admin
        autoload :License, 'qa/ee/page/admin/license'

        module Geo
          module Nodes
            autoload :Show, 'qa/ee/page/admin/geo/nodes/show'
            autoload :New, 'qa/ee/page/admin/geo/nodes/new'
          end
        end
      end
    end

    module Scenario
      module Geo
        autoload :Node, 'qa/ee/scenario/geo/node'
      end

      module Test
        autoload :Geo, 'qa/ee/scenario/test/geo'
      end

      module License
        autoload :Add, 'qa/ee/scenario/license/add'
      end
    end
  end
end
