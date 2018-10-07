module QA
  ##
  # GitLab EE extensions
  #
  module EE
    module Runtime
      autoload :Env, 'qa/ee/runtime/env'
      autoload :Geo, 'qa/ee/runtime/geo'
    end

    module Page
      module Dashboard
        autoload :Projects, 'qa/ee/page/dashboard/projects'
      end

      module Group
        autoload :SamlSSOSignIn, 'qa/ee/page/group/saml_sso_sign_in'

        module Settings
          autoload :SamlSSO, 'qa/ee/page/group/settings/saml_sso'
        end
      end

      module Main
        autoload :Banner, 'qa/ee/page/main/banner'
      end

      module Menu
        autoload :Admin, 'qa/ee/page/menu/admin'
        autoload :Side, 'qa/ee/page/menu/side'
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
        autoload :Show, 'qa/ee/page/project/show'

        module Issue
          autoload :Index, 'qa/ee/page/project/issue/index'
        end

        module Settings
          autoload :ProtectedBranches, 'qa/ee/page/project/settings/protected_branches'
        end
      end

      module MergeRequest
        autoload :Show, 'qa/ee/page/merge_request/show'
      end

      module Group
        module Epic
          autoload :Index, 'qa/ee/page/group/epic/index'
          autoload :Show, 'qa/ee/page/group/epic/show'
          autoload :Edit, 'qa/ee/page/group/epic/edit'
        end
      end
    end

    module Factory
      autoload :License, 'qa/ee/factory/license'

      module Geo
        autoload :Node, 'qa/ee/factory/geo/node'
      end

      module Resource
        autoload :Epic, 'qa/ee/factory/resource/epic'
      end
    end

    module Scenario
      module Test
        autoload :Geo, 'qa/ee/scenario/test/geo'
        module Integration
          autoload :GroupSAML, 'qa/ee/scenario/test/integration/group_saml'
        end
      end
    end
  end
end
