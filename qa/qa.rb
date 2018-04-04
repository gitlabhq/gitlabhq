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
    autoload :Env, 'qa/runtime/env'
    autoload :RSAKey, 'qa/runtime/rsa_key'
    autoload :Address, 'qa/runtime/address'
    autoload :API, 'qa/runtime/api'
  end

  ##
  # GitLab QA fabrication mechanisms
  #
  module Factory
    autoload :Base, 'qa/factory/base'
    autoload :Dependency, 'qa/factory/dependency'
    autoload :Product, 'qa/factory/product'

    module Resource
      autoload :Sandbox, 'qa/factory/resource/sandbox'
      autoload :Group, 'qa/factory/resource/group'
      autoload :Issue, 'qa/factory/resource/issue'
      autoload :Project, 'qa/factory/resource/project'
      autoload :MergeRequest, 'qa/factory/resource/merge_request'
      autoload :DeployKey, 'qa/factory/resource/deploy_key'
      autoload :SecretVariable, 'qa/factory/resource/secret_variable'
      autoload :Runner, 'qa/factory/resource/runner'
      autoload :PersonalAccessToken, 'qa/factory/resource/personal_access_token'
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
    autoload :Taggable, 'qa/scenario/taggable'
    autoload :Template, 'qa/scenario/template'

    ##
    # Test scenario entrypoints.
    #
    module Test
      autoload :Instance, 'qa/scenario/test/instance'

      module Integration
        autoload :LDAP, 'qa/scenario/test/integration/ldap'
        autoload :Mattermost, 'qa/scenario/test/integration/mattermost'
      end

      module Sanity
        autoload :Selectors, 'qa/scenario/test/sanity/selectors'
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
    autoload :View, 'qa/page/view'
    autoload :Element, 'qa/page/element'
    autoload :Validator, 'qa/page/validator'

    module Main
      autoload :Login, 'qa/page/main/login'
      autoload :OAuth, 'qa/page/main/oauth'
    end

    module Settings
      autoload :Common, 'qa/page/settings/common'
    end

    module Menu
      autoload :Main, 'qa/page/menu/main'
      autoload :Side, 'qa/page/menu/side'
      autoload :Admin, 'qa/page/menu/admin'
      autoload :Profile, 'qa/page/menu/profile'
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
      autoload :Activity, 'qa/page/project/activity'

      module Pipeline
        autoload :Index, 'qa/page/project/pipeline/index'
        autoload :Show, 'qa/page/project/pipeline/show'
      end

      module Job
        autoload :Show, 'qa/page/project/job/show'
      end

      module Settings
        autoload :Common, 'qa/page/project/settings/common'
        autoload :Advanced, 'qa/page/project/settings/advanced'
        autoload :Main, 'qa/page/project/settings/main'
        autoload :Repository, 'qa/page/project/settings/repository'
        autoload :CICD, 'qa/page/project/settings/ci_cd'
        autoload :DeployKeys, 'qa/page/project/settings/deploy_keys'
        autoload :SecretVariables, 'qa/page/project/settings/secret_variables'
        autoload :Runners, 'qa/page/project/settings/runners'
        autoload :MergeRequest, 'qa/page/project/settings/merge_request'
      end

      module Issue
        autoload :New, 'qa/page/project/issue/new'
        autoload :Show, 'qa/page/project/issue/show'
        autoload :Index, 'qa/page/project/issue/index'
      end
    end

    module Profile
      autoload :PersonalAccessTokens, 'qa/page/profile/personal_access_tokens'
    end

    module MergeRequest
      autoload :New, 'qa/page/merge_request/new'
      autoload :Show, 'qa/page/merge_request/show'
    end

    module Admin
      module Settings
        autoload :RepositoryStorage, 'qa/page/admin/settings/repository_storage'
        autoload :Main, 'qa/page/admin/settings/main'
      end
    end

    module Mattermost
      autoload :Main, 'qa/page/mattermost/main'
      autoload :Login, 'qa/page/mattermost/login'
    end

    ##
    # Classes describing components that are used by several pages.
    #
    module Component
      autoload :Dropzone, 'qa/page/component/dropzone'
    end
  end

  ##
  # Classes describing operations on Git repositories.
  #
  module Git
    autoload :Repository, 'qa/git/repository'
    autoload :Location, 'qa/git/location'
  end

  ##
  # Classes describing services being part of GitLab and how we can interact
  # with these services, like through the shell.
  #
  module Service
    autoload :Shellout, 'qa/service/shellout'
    autoload :Omnibus, 'qa/service/omnibus'
    autoload :Runner, 'qa/service/runner'
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
