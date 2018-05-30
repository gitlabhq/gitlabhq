lib = File.expand_path(__dir__)
$:.unshift(lib) unless $:.include?(lib)

module QA
  ##
  # GitLab QA fabrication mechanisms
  #
  module Factory
    module Resource
      autoload :Sandbox, 'qa/factory/resource/sandbox'
      autoload :Group, 'qa/factory/resource/group'
      autoload :Issue, 'qa/factory/resource/issue'
      autoload :Project, 'qa/factory/resource/project'
      autoload :MergeRequest, 'qa/factory/resource/merge_request'
      autoload :DeployKey, 'qa/factory/resource/deploy_key'
      autoload :Branch, 'qa/factory/resource/branch'
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
  # Classes describing operations on Git repositories.
  #
  module Git
    autoload :Location, 'qa/git/location'
    autoload :Repository, 'qa/git/repository'
  end

  ##
  # Classes describing structure of GitLab, pages, menus etc.
  #
  # Needed to execute click-driven-only black-box tests.
  #
  module Page
    module Admin
      module Settings
        autoload :Main, 'qa/page/admin/settings/main'
        autoload :RepositoryStorage, 'qa/page/admin/settings/repository_storage'
      end
    end

    ##
    # Classes describing components that are used by several pages.
    #
    module Component
      autoload :Dropzone, 'qa/page/component/dropzone'
    end

    module Dashboard
      autoload :Groups, 'qa/page/dashboard/groups'
      autoload :Projects, 'qa/page/dashboard/projects'
    end

    module Group
      autoload :New, 'qa/page/group/new'
      autoload :Show, 'qa/page/group/show'
    end

    module Main
      autoload :Login, 'qa/page/main/login'
      autoload :OAuth, 'qa/page/main/oauth'
    end

    module Mattermost
      autoload :Login, 'qa/page/mattermost/login'
      autoload :Main, 'qa/page/mattermost/main'
    end

    module Menu
      autoload :Admin, 'qa/page/menu/admin'
      autoload :Main, 'qa/page/menu/main'
      autoload :Profile, 'qa/page/menu/profile'
      autoload :Side, 'qa/page/menu/side'
    end

    module MergeRequest
      autoload :New, 'qa/page/merge_request/new'
      autoload :Show, 'qa/page/merge_request/show'
    end

    module Profile
      autoload :PersonalAccessTokens, 'qa/page/profile/personal_access_tokens'
    end

    module Project
      autoload :Activity, 'qa/page/project/activity'
      autoload :New, 'qa/page/project/new'
      autoload :Show, 'qa/page/project/show'

      module Issue
        autoload :Index, 'qa/page/project/issue/index'
        autoload :New, 'qa/page/project/issue/new'
        autoload :Show, 'qa/page/project/issue/show'
      end

      module Job
        autoload :Show, 'qa/page/project/job/show'
      end

      module Pipeline
        autoload :Index, 'qa/page/project/pipeline/index'
        autoload :Show, 'qa/page/project/pipeline/show'
      end

      module Settings
        autoload :Advanced, 'qa/page/project/settings/advanced'
        autoload :CICD, 'qa/page/project/settings/ci_cd'
        autoload :Common, 'qa/page/project/settings/common'
        autoload :DeployKeys, 'qa/page/project/settings/deploy_keys'
        autoload :Main, 'qa/page/project/settings/main'
        autoload :MergeRequest, 'qa/page/project/settings/merge_request'
        autoload :ProtectedBranches, 'qa/page/project/settings/protected_branches'
        autoload :Repository, 'qa/page/project/settings/repository'
        autoload :Runners, 'qa/page/project/settings/runners'
        autoload :SecretVariables, 'qa/page/project/settings/secret_variables'
      end
    end

    module Settings
      autoload :Common, 'qa/page/settings/common'
    end
  end

  ##
  # GitLab QA runtime classes, mostly singletons.
  #
  module Runtime
    autoload :API, 'qa/runtime/api'
    autoload :Env, 'qa/runtime/env'
    autoload :Namespace, 'qa/runtime/namespace'
    autoload :Release, 'qa/runtime/release'
    autoload :Scenario, 'qa/runtime/scenario'
    autoload :User, 'qa/runtime/user'

    module Key
      autoload :Base, 'qa/runtime/key/base'
      autoload :ECDSA, 'qa/runtime/key/ecdsa'
      autoload :ED25519, 'qa/runtime/key/ed25519'
      autoload :RSA, 'qa/runtime/key/rsa'
    end
  end

  ##
  # GitLab QA Scenarios
  #
  module Scenario
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
  # Classes describing services being part of GitLab and how we can interact
  # with these services, like through the shell.
  #
  module Service
    autoload :Omnibus, 'qa/service/omnibus'
    autoload :Runner, 'qa/service/runner'
  end
end

QA::Runtime::Release.extend_autoloads!

require 'gitlab/qa/framework'
