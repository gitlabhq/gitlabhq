# frozen_string_literal: true

$: << File.expand_path(__dir__)

Encoding.default_external = 'UTF-8'

require_relative '../lib/gitlab'
require_relative '../lib/gitlab/utils'
require_relative '../config/initializers/0_inject_enterprise_edition_module'

require 'chemlab'

module QA
  ##
  # Helper classes to represent frequently used sequences of actions
  # (e.g., login)
  #
  module Flow
    autoload :Login, 'qa/flow/login'
    autoload :Project, 'qa/flow/project'
    autoload :Saml, 'qa/flow/saml'
    autoload :User, 'qa/flow/user'
    autoload :MergeRequest, 'qa/flow/merge_request'
    autoload :Pipeline, 'qa/flow/pipeline'
    autoload :SignUp, 'qa/flow/sign_up'
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
    autoload :AllureReport, 'qa/runtime/allure_report'

    module API
      autoload :Client, 'qa/runtime/api/client'
      autoload :RepositoryStorageMoves, 'qa/runtime/api/repository_storage_moves'
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

    autoload :GroupBase, 'qa/resource/group_base'
    autoload :Sandbox, 'qa/resource/sandbox'
    autoload :Group, 'qa/resource/group'
    autoload :Issue, 'qa/resource/issue'
    autoload :ProjectIssueNote, 'qa/resource/project_issue_note'
    autoload :Project, 'qa/resource/project'
    autoload :LabelBase, 'qa/resource/label_base'
    autoload :ProjectLabel, 'qa/resource/project_label'
    autoload :GroupLabel, 'qa/resource/group_label'
    autoload :MergeRequest, 'qa/resource/merge_request'
    autoload :ProjectImportedFromGithub, 'qa/resource/project_imported_from_github'
    autoload :ProjectImportedFromURL, 'qa/resource/project_imported_from_url'
    autoload :MergeRequestFromFork, 'qa/resource/merge_request_from_fork'
    autoload :DeployKey, 'qa/resource/deploy_key'
    autoload :DeployToken, 'qa/resource/deploy_token'
    autoload :ProtectedBranch, 'qa/resource/protected_branch'
    autoload :Pipeline, 'qa/resource/pipeline'
    autoload :CiVariable, 'qa/resource/ci_variable'
    autoload :Runner, 'qa/resource/runner'
    autoload :PersonalAccessToken, 'qa/resource/personal_access_token'
    autoload :PersonalAccessTokenCache, 'qa/resource/personal_access_token_cache'
    autoload :ProjectAccessToken, 'qa/resource/project_access_token'
    autoload :User, 'qa/resource/user'
    autoload :ProjectMilestone, 'qa/resource/project_milestone'
    autoload :GroupMilestone, 'qa/resource/group_milestone'
    autoload :Members, 'qa/resource/members'
    autoload :File, 'qa/resource/file'
    autoload :Fork, 'qa/resource/fork'
    autoload :SSHKey, 'qa/resource/ssh_key'
    autoload :Snippet, 'qa/resource/snippet'
    autoload :Tag, 'qa/resource/tag'
    autoload :ProjectMember, 'qa/resource/project_member'
    autoload :ProjectSnippet, 'qa/resource/project_snippet'
    autoload :UserGPG, 'qa/resource/user_gpg'
    autoload :Visibility, 'qa/resource/visibility'
    autoload :ProjectSnippet, 'qa/resource/project_snippet'
    autoload :Design, 'qa/resource/design'
    autoload :RegistryRepository, 'qa/resource/registry_repository'
    autoload :Package, 'qa/resource/package'
    autoload :PipelineSchedules, 'qa/resource/pipeline_schedules'
    autoload :ImportProject, 'qa/resource/import_project'

    module KubernetesCluster
      autoload :Base, 'qa/resource/kubernetes_cluster/base'
      autoload :ProjectCluster, 'qa/resource/kubernetes_cluster/project_cluster'
    end

    module Clusters
      autoload :Agent, 'qa/resource/clusters/agent.rb'
      autoload :AgentToken, 'qa/resource/clusters/agent_token.rb'
    end

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

    module Wiki
      autoload :ProjectPage, 'qa/resource/wiki/project_page'
      autoload :GroupPage, 'qa/resource/wiki/group_page'
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
        autoload :Airgapped, 'qa/scenario/test/instance/airgapped'
      end

      module Integration
        autoload :Github, 'qa/scenario/test/integration/github'
        autoload :LDAPNoTLS, 'qa/scenario/test/integration/ldap_no_tls'
        autoload :LDAPNoServer, 'qa/scenario/test/integration/ldap_no_server'
        autoload :LDAPTLS, 'qa/scenario/test/integration/ldap_tls'
        autoload :InstanceSAML, 'qa/scenario/test/integration/instance_saml'
        autoload :Kubernetes, 'qa/scenario/test/integration/kubernetes'
        autoload :Mattermost, 'qa/scenario/test/integration/mattermost'
        autoload :ObjectStorage, 'qa/scenario/test/integration/object_storage'
        autoload :SMTP, 'qa/scenario/test/integration/smtp'
        autoload :SSHTunnel, 'qa/scenario/test/integration/ssh_tunnel'
        autoload :Registry, 'qa/scenario/test/integration/registry'
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
    autoload :PageConcern, 'qa/page/page_concern'
    autoload :Validator, 'qa/page/validator'
    autoload :Validatable, 'qa/page/validatable'

    module SubMenus
      autoload :Common, 'qa/page/sub_menus/common'
    end

    module Main
      autoload :Login, 'qa/page/main/login'
      autoload :Menu, 'qa/page/main/menu'
      autoload :OAuth, 'qa/page/main/oauth'
      autoload :TwoFactorAuth, 'qa/page/main/two_factor_auth'
      autoload :Terms, 'qa/page/main/terms'
    end

    module Registration
      autoload :SignUp, 'qa/page/registration/sign_up'
      autoload :Welcome, 'qa/page/registration/welcome'
    end

    module Settings
      autoload :Common, 'qa/page/settings/common'
    end

    module Dashboard
      autoload :Projects, 'qa/page/dashboard/projects'
      autoload :Groups, 'qa/page/dashboard/groups'
      autoload :Welcome, 'qa/page/dashboard/welcome'
      autoload :Todos, 'qa/page/dashboard/todos'

      module Snippet
        autoload :New, 'qa/page/dashboard/snippet/new'
        autoload :Index, 'qa/page/dashboard/snippet/index'
        autoload :Show, 'qa/page/dashboard/snippet/show'
        autoload :Edit, 'qa/page/dashboard/snippet/edit'
      end
    end

    module Group
      autoload :New, 'qa/page/group/new'
      autoload :Show, 'qa/page/group/show'
      autoload :Menu, 'qa/page/group/menu'
      autoload :Members, 'qa/page/group/members'
      autoload :BulkImport, 'qa/page/group/bulk_import'

      module Milestone
        autoload :Index, 'qa/page/group/milestone/index'
        autoload :New, 'qa/page/group/milestone/new'
      end

      module SubMenus
        autoload :Common, 'qa/page/group/sub_menus/common'
      end

      module Settings
        autoload :General, 'qa/page/group/settings/general'
        autoload :PackageRegistries, 'qa/page/group/settings/package_registries'
      end
    end

    module Milestone
      autoload :Index, 'qa/page/milestone/index'
      autoload :New, 'qa/page/milestone/new'
      autoload :Show, 'qa/page/milestone/show'
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
      autoload :Members, 'qa/page/project/members'

      module Artifact
        autoload :Show, 'qa/page/project/artifact/show'
      end

      module Branches
        autoload :Show, 'qa/page/project/branches/show'
      end

      module Commit
        autoload :Show, 'qa/page/project/commit/show'
      end

      module Import
        autoload :Github, 'qa/page/project/import/github'
        autoload :RepoByURL, 'qa/page/project/import/repo_by_url'
      end

      module Pipeline
        autoload :Index, 'qa/page/project/pipeline/index'
        autoload :Show, 'qa/page/project/pipeline/show'
        autoload :New, 'qa/page/project/pipeline/new'
      end

      module PipelineEditor
        autoload :Show, 'qa/page/project/pipeline_editor/show'
      end

      module Tag
        autoload :Index, 'qa/page/project/tag/index'
        autoload :New, 'qa/page/project/tag/new'
        autoload :Show, 'qa/page/project/tag/show'
      end

      module Job
        autoload :Show, 'qa/page/project/job/show'
      end

      module Packages
        autoload :Index, 'qa/page/project/packages/index'
        autoload :Show, 'qa/page/project/packages/show'
      end

      module Registry
        autoload :Show, 'qa/page/project/registry/show'
      end

      module Settings
        autoload :Advanced, 'qa/page/project/settings/advanced'
        autoload :Main, 'qa/page/project/settings/main'
        autoload :Repository, 'qa/page/project/settings/repository'
        autoload :CICD, 'qa/page/project/settings/ci_cd'
        autoload :Integrations, 'qa/page/project/settings/integrations'
        autoload :GeneralPipelines, 'qa/page/project/settings/general_pipelines'
        autoload :AutoDevops, 'qa/page/project/settings/auto_devops'
        autoload :DeployKeys, 'qa/page/project/settings/deploy_keys'
        autoload :DeployTokens, 'qa/page/project/settings/deploy_tokens'
        autoload :ProtectedBranches, 'qa/page/project/settings/protected_branches'
        autoload :CiVariables, 'qa/page/project/settings/ci_variables'
        autoload :Runners, 'qa/page/project/settings/runners'
        autoload :MergeRequest, 'qa/page/project/settings/merge_request'
        autoload :MirroringRepositories, 'qa/page/project/settings/mirroring_repositories'
        autoload :ProtectedTags, 'qa/page/project/settings/protected_tags'
        autoload :DefaultBranch, 'qa/page/project/settings/default_branch'
        autoload :VisibilityFeaturesPermissions, 'qa/page/project/settings/visibility_features_permissions'
        autoload :AccessTokens, 'qa/page/project/settings/access_tokens'

        module Services
          autoload :Jira, 'qa/page/project/settings/services/jira'
          autoload :Jenkins, 'qa/page/project/settings/services/jenkins'
          autoload :Prometheus, 'qa/page/project/settings/services/prometheus'
        end
        autoload :Monitor, 'qa/page/project/settings/monitor'
        autoload :Alerts, 'qa/page/project/settings/alerts'
        autoload :Integrations, 'qa/page/project/settings/integrations'
      end

      module SubMenus
        autoload :CiCd, 'qa/page/project/sub_menus/ci_cd'
        autoload :Common, 'qa/page/project/sub_menus/common'
        autoload :Issues, 'qa/page/project/sub_menus/issues'
        autoload :Monitor, 'qa/page/project/sub_menus/monitor'
        autoload :Deployments, 'qa/page/project/sub_menus/deployments'
        autoload :Infrastructure, 'qa/page/project/sub_menus/infrastructure'
        autoload :Repository, 'qa/page/project/sub_menus/repository'
        autoload :Settings, 'qa/page/project/sub_menus/settings'
        autoload :Project, 'qa/page/project/sub_menus/project'
        autoload :Packages, 'qa/page/project/sub_menus/packages'
      end

      module Issue
        autoload :New, 'qa/page/project/issue/new'
        autoload :Show, 'qa/page/project/issue/show'
        autoload :Index, 'qa/page/project/issue/index'
        autoload :JiraImport, 'qa/page/project/issue/jira_import'
      end

      module Fork
        autoload :New, 'qa/page/project/fork/new'
      end

      module Milestone
        autoload :New, 'qa/page/project/milestone/new'
        autoload :Index, 'qa/page/project/milestone/index'
      end

      module Deployments
        module Environments
          autoload :Index, 'qa/page/project/deployments/environments/index'
          autoload :Show, 'qa/page/project/deployments/environments/show'
        end
      end

      module Infrastructure
        module Kubernetes
          autoload :Index, 'qa/page/project/infrastructure/kubernetes/index'
          autoload :Add, 'qa/page/project/infrastructure/kubernetes/add'
          autoload :AddExisting, 'qa/page/project/infrastructure/kubernetes/add_existing'
          autoload :Show, 'qa/page/project/infrastructure/kubernetes/show'
        end
      end

      module Monitor
        module Metrics
          autoload :Show, 'qa/page/project/monitor/metrics/show'
        end

        module Incidents
          autoload :Index, 'qa/page/project/monitor/incidents/index'
        end
      end

      module Wiki
        autoload :Edit, 'qa/page/project/wiki/edit'
        autoload :Show, 'qa/page/project/wiki/show'
        autoload :GitAccess, 'qa/page/project/wiki/git_access'
        autoload :List, 'qa/page/project/wiki/list'
      end

      module WebIDE
        autoload :Edit, 'qa/page/project/web_ide/edit'
      end

      module Snippet
        autoload :New, 'qa/page/project/snippet/new'
        autoload :Show, 'qa/page/project/snippet/show'
        autoload :Index, 'qa/page/project/snippet/index'
      end
    end

    module Profile
      autoload :Menu, 'qa/page/profile/menu'
      autoload :PersonalAccessTokens, 'qa/page/profile/personal_access_tokens'
      autoload :SSHKeys, 'qa/page/profile/ssh_keys'
      autoload :Emails, 'qa/page/profile/emails'
      autoload :Password, 'qa/page/profile/password'
      autoload :TwoFactorAuth, 'qa/page/profile/two_factor_auth'

      module Accounts
        autoload :Show, 'qa/page/profile/accounts/show'
      end
    end

    module User
      autoload :Show, 'qa/page/user/show'
    end

    module Issuable
      autoload :New, 'qa/page/issuable/new'
    end

    module Alert
      autoload :AutoDevopsAlert, 'qa/page/alert/auto_devops_alert'
      autoload :FreeTrial, 'qa/page/alert/free_trial'
    end

    module Layout
      autoload :Banner, 'qa/page/layout/banner'
      autoload :Flash, 'qa/page/layout/flash'
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
        autoload :General, 'qa/page/admin/settings/general'
        autoload :MetricsAndProfiling, 'qa/page/admin/settings/metrics_and_profiling'
        autoload :Network, 'qa/page/admin/settings/network'

        module Component
          autoload :IpLimits, 'qa/page/admin/settings/component/ip_limits'
          autoload :OutboundRequests, 'qa/page/admin/settings/component/outbound_requests'
          autoload :AccountAndLimit, 'qa/page/admin/settings/component/account_and_limit'
          autoload :PerformanceBar, 'qa/page/admin/settings/component/performance_bar'
          autoload :SignUpRestrictions, 'qa/page/admin/settings/component/sign_up_restrictions'
        end
      end

      module Overview
        module Users
          autoload :Index, 'qa/page/admin/overview/users/index'
          autoload :Show, 'qa/page/admin/overview/users/show'
        end

        module Groups
          autoload :Index, 'qa/page/admin/overview/groups/index'
          autoload :Show, 'qa/page/admin/overview/groups/show'
          autoload :Edit, 'qa/page/admin/overview/groups/edit'
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
      autoload :Breadcrumbs, 'qa/page/component/breadcrumbs'
      autoload :CiBadgeLink, 'qa/page/component/ci_badge_link'
      autoload :ClonePanel, 'qa/page/component/clone_panel'
      autoload :DesignManagement, 'qa/page/component/design_management'
      autoload :LazyLoader, 'qa/page/component/lazy_loader'
      autoload :LegacyClonePanel, 'qa/page/component/legacy_clone_panel'
      autoload :Dropzone, 'qa/page/component/dropzone'
      autoload :GroupsFilter, 'qa/page/component/groups_filter'
      autoload :Select2, 'qa/page/component/select2'
      autoload :DropdownFilter, 'qa/page/component/dropdown_filter'
      autoload :UsersSelect, 'qa/page/component/users_select'
      autoload :Note, 'qa/page/component/note'
      autoload :ConfirmModal, 'qa/page/component/confirm_modal'
      autoload :CustomMetric, 'qa/page/component/custom_metric'
      autoload :DesignManagement, 'qa/page/component/design_management'
      autoload :ProjectSelector, 'qa/page/component/project_selector'
      autoload :Snippet, 'qa/page/component/snippet'
      autoload :NewSnippet, 'qa/page/component/new_snippet'
      autoload :InviteMembersModal, 'qa/page/component/invite_members_modal'
      autoload :Wiki, 'qa/page/component/wiki'
      autoload :WikiSidebar, 'qa/page/component/wiki_sidebar'
      autoload :WikiPageForm, 'qa/page/component/wiki_page_form'
      autoload :AccessTokens, 'qa/page/component/access_tokens'
      autoload :CommitModal, 'qa/page/component/commit_modal'
      autoload :VisibilitySetting, 'qa/page/component/visibility_setting'

      module Import
        autoload :Gitlab, 'qa/page/component/import/gitlab'
        autoload :Selection, 'qa/page/component/import/selection'
      end

      module Issuable
        autoload :Common, 'qa/page/component/issuable/common'
        autoload :Sidebar, 'qa/page/component/issuable/sidebar'
      end

      module IssueBoard
        autoload :Show, 'qa/page/component/issue_board/show'
      end

      module WebIDE
        autoload :Alert, 'qa/page/component/web_ide/alert'

        module Modal
          autoload :CreateNewFile, 'qa/page/component/web_ide/modal/create_new_file'
        end
      end

      module Project
        autoload :Templates, 'qa/page/component/project/templates'
      end
    end

    module Trials
      autoload :New, 'qa/page/trials/new'
      autoload :Select, 'qa/page/trials/select'
    end

    module Modal
      autoload :DeleteWiki, 'qa/page/modal/delete_wiki'
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
    autoload :PraefectManager, 'qa/service/praefect_manager'

    module ClusterProvider
      autoload :Base, 'qa/service/cluster_provider/base'
      autoload :Gcloud, 'qa/service/cluster_provider/gcloud'
      autoload :Minikube, 'qa/service/cluster_provider/minikube'
      autoload :K3d, 'qa/service/cluster_provider/k3d'
      autoload :K3s, 'qa/service/cluster_provider/k3s'
      autoload :K3sCilium, 'qa/service/cluster_provider/k3s_cilium'
    end

    module DockerRun
      autoload :Base, 'qa/service/docker_run/base'
      autoload :Jenkins, 'qa/service/docker_run/jenkins'
      autoload :LDAP, 'qa/service/docker_run/ldap'
      autoload :Maven, 'qa/service/docker_run/maven'
      autoload :NodeJs, 'qa/service/docker_run/node_js'
      autoload :GitlabRunner, 'qa/service/docker_run/gitlab_runner'
      autoload :MailHog, 'qa/service/docker_run/mail_hog'
      autoload :SamlIdp, 'qa/service/docker_run/saml_idp'
      autoload :K3s, 'qa/service/docker_run/k3s'
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
      autoload :ContextSelector, 'qa/specs/helpers/context_selector'
      autoload :Quarantine, 'qa/specs/helpers/quarantine'
      autoload :RSpec, 'qa/specs/helpers/rspec'
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
        autoload :LastJobConsole, 'qa/vendor/jenkins/page/last_job_console'
        autoload :ConfigureJob, 'qa/vendor/jenkins/page/configure_job'
      end
    end

    module Jira
      autoload :JiraAPI, 'qa/vendor/jira/jira_api'
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
    autoload :Repeater, 'qa/support/repeater'
    autoload :Run, 'qa/support/run'
    autoload :Retrier, 'qa/support/retrier'
    autoload :Waiter, 'qa/support/waiter'
    autoload :WaitForRequests, 'qa/support/wait_for_requests'
    autoload :OTP, 'qa/support/otp'
    autoload :SSH, 'qa/support/ssh'
  end
end

QA::Runtime::Release.extend_autoloads!
