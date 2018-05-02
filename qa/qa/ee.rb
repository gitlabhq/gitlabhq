module QA
  ##
  # GitLab EE extensions
  #
  module EE
    module Page
      module Menu
        autoload :Admin, 'qa/ee/page/menu/admin'
      end

      module Admin
        autoload :License, 'qa/ee/page/admin/license'

        module Geo
          module Nodes
            autoload :Show, 'qa/ee/page/admin/geo/nodes/show'
            autoload :New, 'qa/ee/page/admin/geo/nodes/new'
          end
        end
      end

      module Project
        module Settings
          autoload :ProtectedBranches, 'qa/ee/page/project/settings/protected_branches'
        end
      end

      module MergeRequest
        autoload :Show, 'qa/ee/page/merge_request/show'
      end
    end

    module Factory
      autoload :License, 'qa/ee/factory/license'

      module Geo
        autoload :Node, 'qa/ee/factory/geo/node'
      end
    end

    module Scenario
      module Test
        autoload :Geo, 'qa/ee/scenario/test/geo'
      end
    end
  end
end
