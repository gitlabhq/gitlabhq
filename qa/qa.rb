# frozen_string_literal: true

$: << File.expand_path(File.dirname(__FILE__))

Encoding.default_external = 'UTF-8'

require_relative '../lib/gitlab'
require_relative '../lib/gitlab/utils'
require_relative '../config/initializers/0_inject_enterprise_edition_module'

module QA
  ##
  # Helper classes to represent frequently used sequences of actions
  # (e.g., login)
  #
  module Flow
    autoload :Login, 'qa/flow/login'
    autoload :Project, 'qa/flow/project'
  end

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
    autoload :Address, 'qa/runtime/address'
    autoload :Path, 'qa/runtime/path'
    autoload :Feature, 'qa/runtime/feature'
    autoload :Fixtures, 'qa/runtime/fixtures'
    autoload :Logger, 'qa/runtime/logger'
    autoload :GPG, 'qa/runtime/gpg'
    autoload :MailHog, 'qa/runtime/mail_hog'
    autoload :IPAddress, 'qa/runtime/ip_address'
    autoload :Search, 'qa/runtime/search'
    autoload :ApplicationSettings, 'qa/runtime/application_settings'

    module API
      autoload :Client, 'qa/runtime/api/client'
      autoload :Request, 'qa/runtime/api/request'
    end

    module Key
      autoload :Base, 'qa/runtime/key/base'
      autoload :RSA, 'qa/runtime/key/rsa'
      autoload :ECDSA, 'qa/runtime/key/ecdsa'
      autoload :ED25519, 'qa/runtime/key/ed25519'
    end
  end

  ##
  # GitLab QA fabrication mechanisms
  #
  module Resource
    autoload :ApiFabricator, 'qa/resource/api_fabricator'
    autoload :Base, 'qa/resource/base'

    autoload :Sandbox, 'qa/resource/sandbox'
    autoload :Group, 'qa/resource/group'
    autoload :Issue, 'qa/resource/issue'
    autoload :Project, 'qa/resource/project'
    autoload :Label, 'qa/resource/label'
    autoload :MergeRequest, 'qa/resource/merge_request'
    autoload :ProjectImportedFromGithub, 'qa/resource/project_imported_from_github'
    autoload :MergeRequestFromFork, 'qa/resource/merge_request_from_fork'
    autoload :DeployKey, 'qa/resource/deploy_key'
    autoload :DeployToken, 'qa/resource/deploy_token'
    autoload :ProtectedBranch, 'qa/resource/protected_branch'
    autoload :CiVariable, 'qa/resource/ci_variable'
    autoload :Runner, 'qa/resource/runner'
    autoload :PersonalAccessToken, 'qa/resource/personal_access_token'
    autoload :KubernetesCluster, 'qa/resource/kubernetes_cluster'
    autoload :User, 'qa/resource/user'
    autoload :ProjectMilestone, 'qa/resource/project_milestone'
    autoload :Members, 'qa/resource/members'
    autoload :Wiki, 'qa/resource/wiki'
    autoload :File, 'qa/resource/file'
    autoload :Fork, 'qa/resource/fork'
    autoload :SSHKey, 'qa/resource/ssh_key'
    autoload :Snippet, 'qa/resource/snippet'
    autoload :Tag, 'qa/resource/tag'
    autoload :ProjectMember, 'qa/resource/project_member'
    autoload :UserGPG, 'qa/resource/user_gpg'

    module Events
      autoload :Base, 'qa/resource/events/base'
      autoload :Project, 'qa/resource/events/project'
    end

    module Repository
      autoload :Commit, 'qa/resource/repository/commit'
      autoload :Push, 'qa/resource/repository/push'
      autoload :ProjectPush, 'qa/resource/repository/project_push'
      autoload :WikiPush, 'qa/resource/repository/wiki_push'
    end

    module Settings
      autoload :HashedStorage, 'qa/resource/settings/hashed_storage'
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
    autoload :Template, 'qa/scenario/template'
    autoload :SharedAttributes, 'qa/scenario/shared_attributes'

    ##
    # Test scenario entrypoints.
    #
    module Test
      autoload :Instance, 'qa/scenario/test/instance'
      module Instance
        autoload :All, 'qa/scenario/test/instance/all'
        autoload :Smoke, 'qa/scenario/test/instance/smoke'
      end

      module Integration
        autoload :Github, 'qa/scenario/test/integration/github'
        autoload :LDAPNoTLS, 'qa/scenario/test/integration/ldap_no_tls'
        autoload :LDAPNoServer, 'qa/scenario/test/integration/ldap_no_server'
        autoload :LDAPTLS, 'qa/scenario/test/integration/ldap_tls'
        autoload :InstanceSAML, 'qa/scenario/test/integration/instance_saml'
        autoload :OAuth, 'qa/scenario/test/integration/oauth'
        autoload :Kubernetes, 'qa/scenario/test/integration/kubernetes'
        autoload :Mattermost, 'qa/scenario/test/integration/mattermost'
        autoload :ObjectStorage, 'qa/scenario/test/integration/object_storage'
        autoload :SMTP, 'qa/scenario/test/integration/smtp'
      end

      module Sanity
        autoload :Framework, 'qa/scenario/test/sanity/framework'
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
    autoload :Validatable, 'qa/page/validatable'

    module Main
      autoload :Login, 'qa/page/main/login'
      autoload :Menu, 'qa/page/main/menu'
      autoload :OAuth, 'qa/page/main/oauth'
      autoload :SignUp, 'qa/page/main/sign_up'
    end

    module Settings
      autoload :Common, 'qa/page/settings/common'
    end

    module Dashboard
      autoload :Projects, 'qa/page/dashboard/projects'
      autoload :Groups, 'qa/page/dashboard/groups'
      autoload :Welcome, 'qa/page/dashboard/welcome'

      module Snippet
        autoload :New, 'qa/page/dashboard/snippet/new'
        autoload :Index, 'qa/page/dashboard/snippet/index'
        autoload :Show, 'qa/page/dashboard/snippet/show'
      end
    end

    module Group
      autoload :New, 'qa/page/group/new'
      autoload :Show, 'qa/page/group/show'
      autoload :Menu, 'qa/page/group/menu'

      module SubMenus
        autoload :Common, 'qa/page/group/sub_menus/common'
        autoload :Members, 'qa/page/group/sub_menus/members'
      end

      module Settings
        autoload :General, 'qa/page/group/settings/general'
      end
    end

    module File
      autoload :Form, 'qa/page/file/form'
      autoload :Show, 'qa/page/file/show'
      autoload :Edit, 'qa/page/file/edit'

      module Shared
        autoload :CommitMessage, 'qa/page/file/shared/commit_message'
        autoload :CommitButton, 'qa/page/file/shared/commit_button'
        autoload :Editor, 'qa/page/file/shared/editor'
      end
    end

    module Project
      autoload :New, 'qa/page/project/new'
      autoload :Show, 'qa/page/project/show'
      autoload :Activity, 'qa/page/project/activity'
      autoload :Menu, 'qa/page/project/menu'

      module Branches
        autoload :Show, 'qa/page/project/branches/show'
      end

      module Commit
        autoload :Show, 'qa/page/project/commit/show'
      end

      module Import
        autoload :Github, 'qa/page/project/import/github'
      end

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
        autoload :AutoDevops, 'qa/page/project/settings/auto_devops'
        autoload :DeployKeys, 'qa/page/project/settings/deploy_keys'
        autoload :DeployTokens, 'qa/page/project/settings/deploy_tokens'
        autoload :ProtectedBranches, 'qa/page/project/settings/protected_branches'
        autoload :CiVariables, 'qa/page/project/settings/ci_variables'
        autoload :Runners, 'qa/page/project/settings/runners'
        autoload :MergeRequest, 'qa/page/project/settings/merge_request'
        autoload :Members, 'qa/page/project/settings/members'
        autoload :MirroringRepositories, 'qa/page/project/settings/mirroring_repositories'
        autoload :VisibilityFeaturesPermissions, 'qa/page/project/settings/visibility_features_permissions'
      end

      module SubMenus
        autoload :CiCd, 'qa/page/project/sub_menus/ci_cd'
        autoload :Common, 'qa/page/project/sub_menus/common'
        autoload :Issues, 'qa/page/project/sub_menus/issues'
        autoload :Operations, 'qa/page/project/sub_menus/operations'
        autoload :Repository, 'qa/page/project/sub_menus/repository'
        autoload :Settings, 'qa/page/project/sub_menus/settings'
        autoload :Project, 'qa/page/project/sub_menus/project'
      end

      module Issue
        autoload :New, 'qa/page/project/issue/new'
        autoload :Show, 'qa/page/project/issue/show'
        autoload :Index, 'qa/page/project/issue/index'
      end

      module Fork
        autoload :New, 'qa/page/project/fork/new'
      end

      module Milestone
        autoload :New, 'qa/page/project/milestone/new'
        autoload :Index, 'qa/page/project/milestone/index'
      end

      module Operations
        module Environments
          autoload :Index, 'qa/page/project/operations/environments/index'
          autoload :Show, 'qa/page/project/operations/environments/show'
        end

        module Kubernetes
          autoload :Index, 'qa/page/project/operations/kubernetes/index'
          autoload :Add, 'qa/page/project/operations/kubernetes/add'
          autoload :AddExisting, 'qa/page/project/operations/kubernetes/add_existing'
          autoload :Show, 'qa/page/project/operations/kubernetes/show'
        end
      end

      module Wiki
        autoload :Edit, 'qa/page/project/wiki/edit'
        autoload :New, 'qa/page/project/wiki/new'
        autoload :Show, 'qa/page/project/wiki/show'
        autoload :GitAccess, 'qa/page/project/wiki/git_access'
      end

      module WebIDE
        autoload :Edit, 'qa/page/project/web_ide/edit'
      end
    end

    module Profile
      autoload :Menu, 'qa/page/profile/menu'
      autoload :PersonalAccessTokens, 'qa/page/profile/personal_access_tokens'
      autoload :SSHKeys, 'qa/page/profile/ssh_keys'
      autoload :Emails, 'qa/page/profile/emails'
      autoload :Password, 'qa/page/profile/password'
      autoload :TwoFactorAuth, 'qa/page/profile/two_factor_auth'
    end

    module Issuable
      autoload :Sidebar, 'qa/page/issuable/sidebar'
    end

    module Alert
      autoload :AutoDevopsAlert, 'qa/page/alert/auto_devops_alert'
    end

    module Layout
      autoload :Banner, 'qa/page/layout/banner'
      autoload :PerformanceBar, 'qa/page/layout/performance_bar'
    end

    module Label
      autoload :New, 'qa/page/label/new'
      autoload :Index, 'qa/page/label/index'
    end

    module MergeRequest
      autoload :New, 'qa/page/merge_request/new'
      autoload :Show, 'qa/page/merge_request/show'
    end

    module Admin
      autoload :Menu, 'qa/page/admin/menu'
      autoload :NewSession, 'qa/page/admin/new_session'

      module Settings
        autoload :Repository, 'qa/page/admin/settings/repository'
        autoload :General, 'qa/page/admin/settings/general'
        autoload :MetricsAndProfiling, 'qa/page/admin/settings/metrics_and_profiling'
        autoload :Network, 'qa/page/admin/settings/network'

        module Component
          autoload :IpLimits, 'qa/page/admin/settings/component/ip_limits'
          autoload :OutboundRequests, 'qa/page/admin/settings/component/outbound_requests'
          autoload :RepositoryStorage, 'qa/page/admin/settings/component/repository_storage'
          autoload :AccountAndLimit, 'qa/page/admin/settings/component/account_and_limit'
          autoload :PerformanceBar, 'qa/page/admin/settings/component/performance_bar'
        end
      end

      module Overview
        module Users
          autoload :Index, 'qa/page/admin/overview/users/index'
          autoload :Show, 'qa/page/admin/overview/users/show'
        end
      end
    end

    module Mattermost
      autoload :Main, 'qa/page/mattermost/main'
      autoload :Login, 'qa/page/mattermost/login'
    end

    module Search
      autoload :Results, 'qa/page/search/results'
    end

    ##
    # Classes describing components that are used by several pages.
    #
    module Component
      autoload :CiBadgeLink, 'qa/page/component/ci_badge_link'
      autoload :ClonePanel, 'qa/page/component/clone_panel'
      autoload :LazyLoader, 'qa/page/component/lazy_loader'
      autoload :LegacyClonePanel, 'qa/page/component/legacy_clone_panel'
      autoload :Dropzone, 'qa/page/component/dropzone'
      autoload :GroupsFilter, 'qa/page/component/groups_filter'
      autoload :Select2, 'qa/page/component/select2'
      autoload :DropdownFilter, 'qa/page/component/dropdown_filter'
      autoload :UsersSelect, 'qa/page/component/users_select'
      autoload :Note, 'qa/page/component/note'
      autoload :ConfirmModal, 'qa/page/component/confirm_modal'

      module Issuable
        autoload :Common, 'qa/page/component/issuable/common'
      end

      module WebIDE
        autoload :Alert, 'qa/page/component/web_ide/alert'
      end
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
    autoload :KubernetesCluster, 'qa/service/kubernetes_cluster'
    autoload :Omnibus, 'qa/service/omnibus'

    module ClusterProvider
      autoload :Base, 'qa/service/cluster_provider/base'
      autoload :Gcloud, 'qa/service/cluster_provider/gcloud'
      autoload :Minikube, 'qa/service/cluster_provider/minikube'
      autoload :K3d, 'qa/service/cluster_provider/k3d'
    end

    module DockerRun
      autoload :Base, 'qa/service/docker_run/base'
      autoload :Jenkins, 'qa/service/docker_run/jenkins'
      autoload :LDAP, 'qa/service/docker_run/ldap'
      autoload :Maven, 'qa/service/docker_run/maven'
      autoload :NodeJs, 'qa/service/docker_run/node_js'
      autoload :GitlabRunner, 'qa/service/docker_run/gitlab_runner'
      autoload :MailHog, 'qa/service/docker_run/mail_hog'
    end
  end

  ##
  # Classes that make it possible to execute features tests.
  #
  module Specs
    autoload :Config, 'qa/specs/config'
    autoload :Runner, 'qa/specs/runner'
    autoload :ParallelRunner, 'qa/specs/parallel_runner'
    autoload :LoopRunner, 'qa/specs/loop_runner'

    module Helpers
      autoload :Quarantine, 'qa/specs/helpers/quarantine'
    end
  end

  ##
  # Classes that describe the structure of vendor/third party application pages
  #
  module Vendor
    module SAMLIdp
      module Page
        autoload :Base, 'qa/vendor/saml_idp/page/base'
        autoload :Login, 'qa/vendor/saml_idp/page/login'
      end
    end

    module Jenkins
      module Page
        autoload :Base, 'qa/vendor/jenkins/page/base'
        autoload :Login, 'qa/vendor/jenkins/page/login'
        autoload :Configure, 'qa/vendor/jenkins/page/configure'
        autoload :NewCredentials, 'qa/vendor/jenkins/page/new_credentials'
        autoload :NewJob, 'qa/vendor/jenkins/page/new_job'
        autoload :ConfigureJob, 'qa/vendor/jenkins/page/configure_job'
      end
    end

    module Github
      module Page
        autoload :Base, 'qa/vendor/github/page/base'
        autoload :Login, 'qa/vendor/github/page/login'
      end
    end

    module OnePassword
      autoload :CLI, 'qa/vendor/one_password/cli'
    end
  end

  # Classes that provide support to other parts of the framework.
  #
  module Support
    module Page
      autoload :Logging, 'qa/support/page/logging'
    end
    autoload :Api, 'qa/support/api'
    autoload :Dates, 'qa/support/dates'
    autoload :Waiter, 'qa/support/waiter'
    autoload :Retrier, 'qa/support/retrier'
    autoload :WaitForRequests, 'qa/support/wait_for_requests'
  end
end

QA::Runtime::Release.extend_autoloads!
