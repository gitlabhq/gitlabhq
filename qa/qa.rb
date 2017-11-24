$: << File.expand_path(File.dirname(__FILE__))

module QA
  ##
  # GitLab QA runtime classes, mostly singletons.
  #
  module Runtime
    autoload :Release, 'qa/runtime/release'
    autoload :User, 'qa/runtime/user'
    autoload :Namespace, 'qa/runtime/namespace'
    autoload :Scenario, 'qa/runtime/scenario'
  end

  ##
  # GitLab QA Scenarios
  #
  module Scenario
    ##
    # Support files
    #
    autoload :Bootable, 'qa/scenario/bootable'
    autoload :Actable, 'qa/scenario/actable'
    autoload :Entrypoint, 'qa/scenario/entrypoint'
    autoload :Template, 'qa/scenario/template'

    ##
    # Test scenario entrypoints.
    #
    module Test
      autoload :Instance, 'qa/scenario/test/instance'

      module Integration
        autoload :Mattermost, 'qa/scenario/test/integration/mattermost'
      end
    end

    ##
    # GitLab instance scenarios.
    #
    module Gitlab
      module Group
        autoload :Create, 'qa/scenario/gitlab/group/create'
      end

      module Project
        autoload :Create, 'qa/scenario/gitlab/project/create'
        module Repository
          module Branch
            autoload :Create, 'qa/scenario/gitlab/project/repository/branch/create'
          end
        end

        module Settings
          module Repository
            autoload :ProtectBranch, 'qa/scenario/gitlab/project/settings/repository/protect_branch.rb'
          end
        end
      end

      module Sandbox
        autoload :Prepare, 'qa/scenario/gitlab/sandbox/prepare'
      end

      module Admin
        autoload :HashedStorage, 'qa/scenario/gitlab/admin/hashed_storage'
      end
    end
  end

  ##
  # Classes describing structure of GitLab, pages, menus etc.
  #
  # Needed to execute click-driven-only black-box tests.
  #
  module Page
    autoload :Base, 'qa/page/base'

    module Main
      autoload :Entry, 'qa/page/main/entry'
      autoload :Login, 'qa/page/main/login'
      autoload :Menu, 'qa/page/main/menu'
      autoload :OAuth, 'qa/page/main/oauth'
    end

    module Dashboard
      autoload :Projects, 'qa/page/dashboard/projects'
      autoload :Groups, 'qa/page/dashboard/groups'
    end

    module Group
      autoload :New, 'qa/page/group/new'
      autoload :Show, 'qa/page/group/show'
    end

    module Project
      autoload :New, 'qa/page/project/new'
      autoload :Show, 'qa/page/project/show'
      autoload :Menu, 'qa/page/project/menu'

      module Repository
        autoload :Branches, 'qa/page/project/repository/branches'

        module Branch
          autoload :New, 'qa/page/project/repository/branch/new'
        end
      end

      module Settings
        autoload :Menu, 'qa/page/project/settings/menu'
        autoload :Repository, 'qa/page/project/settings/repository'
      end
    end

    module Admin
      autoload :Menu, 'qa/page/admin/menu'
      autoload :Settings, 'qa/page/admin/settings'
    end

    module Mattermost
      autoload :Main, 'qa/page/mattermost/main'
      autoload :Login, 'qa/page/mattermost/login'
    end
  end

  ##
  # Classes describing operations on Git repositories.
  #
  module Git
    autoload :Repository, 'qa/git/repository'
  end

  ##
  # Classes describing shell interaction with GitLab
  #
  module Shell
    autoload :Omnibus, 'qa/shell/omnibus'
  end

  ##
  # Classes that make it possible to execute features tests.
  #
  module Specs
    autoload :Config, 'qa/specs/config'
    autoload :Runner, 'qa/specs/runner'
  end
end

QA::Runtime::Release.extend_autoloads!
