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
    autoload :Browser, 'qa/runtime/browser'
  end

  ##
  # GitLab QA fabrication mechanisms
  #
  module Factory
    autoload :Base, 'qa/factory/base'

    module Resource
      autoload :Sandbox, 'qa/factory/resource/sandbox'
      autoload :Group, 'qa/factory/resource/group'
      autoload :Project, 'qa/factory/resource/project'
    end

    module Repository
      autoload :Push, 'qa/factory/repository/push'
    end

    module Settings
      autoload :HashedStorage, 'qa/factory/settings/hashed_storage'
    end
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
  end

  ##
  # Classes describing structure of GitLab, pages, menus etc.
  #
  # Needed to execute click-driven-only black-box tests.
  #
  module Page
    autoload :Base, 'qa/page/base'

    module Main
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
