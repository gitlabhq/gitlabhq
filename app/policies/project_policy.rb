# frozen_string_literal: true

class ProjectPolicy < BasePolicy
  include ::Ci::JobAbilities
  include ::Authz::RolePermissions
  include ::Authn::SubgroupProvisionedServiceAccountRestriction

  define_role_permissions(:project)

  # https://docs.gitlab.com/18.2/ci/pipelines/settings/#change-which-users-can-view-your-pipelines
  desc "Project-based pipeline visibility enabled"
  condition(:public_builds, scope: :subject, score: 0) { project.public_builds? }

  # For guest access we use #team_member? so we can use
  # project.members, which gets cached in subject scope.
  # This is safe because team_access_level is guaranteed
  # by ProjectAuthorization's validation to be at minimum
  # GUEST
  desc "User has guest access"
  condition(:guest) { team_member? }

  desc "User has owner access"
  condition :owner do
    owner_of_personal_namespace = project.owner.present? && project.owner == @user

    unless owner_of_personal_namespace
      group_or_project_owner = team_access_level >= Gitlab::Access::OWNER
    end

    owner_of_personal_namespace || group_or_project_owner
  end

  desc "User is a project bot"
  condition(:project_bot) { user.project_bot? && team_member? }

  desc "Project is public"
  condition(:public_project, scope: :subject, score: 0) { project.public? }

  desc "project is private"
  condition(:private_project, scope: :subject, score: 0) { project.private? }

  desc "Project is visible to internal users"
  condition(:internal_access) do
    next false unless user

    project.internal? && !user.external?
  end

  desc "User owns the project's organization"
  condition(:organization_owner) { owns_organization?(@subject.organization) }

  rule { admin | organization_owner }.enable :read_all_organization_resources

  desc "User already has access to the project or its group, or has a pending group access request"
  condition(:has_project_access_or_pending_request) do
    team_access_level >= Gitlab::Access::GUEST ||
      project_group_member? ||
      project_group_requester?
  end

  desc "User is external"
  condition(:external_user) { user.external? }

  desc "Project is archived"
  condition(:archived, scope: :subject, score: 0) { project.self_or_ancestors_archived? }

  desc "Project is scheduled for deletion"
  condition(:deletion_scheduled, scope: :subject) { project.marked_for_deletion_at.present? }

  desc "Project pipeline variables minimum override role is in a privileged state"
  condition(:project_pipeline_override_role_privileged) { project.pipeline_override_role_privileged? }

  desc "Project is in the process of being deleted"
  condition(:self_deletion_in_progress) { project.self_deletion_in_progress? }

  condition(:default_issues_tracker, scope: :subject) { project.default_issues_tracker? }

  desc "Container registry is disabled"
  # Do not use the scope option here as this condition depends
  # on both the user and the subject, and can lead to bugs like
  # https://gitlab.com/gitlab-org/gitlab/-/issues/391551
  condition(:container_registry_disabled) do
    if user.is_a?(DeployToken)
      (!user.read_registry? && !user.write_registry?) ||
        user.revoked? ||
        !project.container_registry_enabled?
    else
      !access_allowed_to?(:container_registry)
    end
  end

  desc "Project has an external wiki"
  condition(:has_external_wiki, scope: :subject, score: 0) { project.has_external_wiki? }

  desc "Project has request access enabled"
  condition(:request_access_enabled, scope: :subject, score: 0) { project.request_access_enabled }

  desc "Has merge requests allowing pushes to user"
  condition(:has_merge_requests_allowing_pushes) do
    next false unless user_is_user?

    project.merge_requests_allowing_push_to_user(user).any?
  end

  desc "Deploy key with read access"
  condition(:download_code_deploy_key) do
    user.is_a?(DeployKey) && user.has_access_to?(project)
  end

  desc "Deploy key with write access"
  condition(:push_code_deploy_key) do
    user.is_a?(DeployKey) && user.can_push_to?(project)
  end

  desc "Deploy token with read_container_image scope"
  condition(:read_container_image_deploy_token) do
    user.is_a?(DeployToken) && user.has_access_to?(project) && user.read_registry?
  end

  desc "Deploy token with create_container_image scope"
  condition(:create_container_image_deploy_token) do
    user.is_a?(DeployToken) && user.has_access_to?(project) && user.write_registry?
  end

  desc "Deploy token with read_package_registry scope"
  condition(:read_package_registry_deploy_token) do
    user.is_a?(DeployToken) && user.has_access_to?(project) && user.read_package_registry
  end

  desc "Deploy token with write_package_registry scope"
  condition(:write_package_registry_deploy_token) do
    user.is_a?(DeployToken) && user.has_access_to?(project) && user.write_package_registry
  end

  desc "Deploy token with read_repository scope and project access"
  condition(:download_code_deploy_token) do
    user.is_a?(DeployToken) && user.read_repository && user.has_access_to?(project)
  end

  desc "If user is authenticated via CI job token then the target project should be in scope"
  condition(:project_allowed_for_job_token_by_scope) do
    !@user&.from_ci_job_token? || @user.ci_job_token_scope.accessible?(project)
  end

  desc "Public, internal or project in the scope allowed via CI job token"
  condition(:project_allowed_for_job_token) do
    public_project? || internal_access? || project_allowed_for_job_token_by_scope?
  end

  desc "If the project is either public or internal"
  condition(:public_or_internal) do
    project.public? || project.internal?
  end

  desc "If the pages is public"
  condition(:public_pages) do
    project.public_pages?
  end

  desc "If the pages is internal"
  condition(:internal_pages) do
    project.project_feature.pages_access_level == ProjectFeature::ENABLED
  end

  condition(:private_package_registry) do
    project.project_feature.package_registry_access_level == ProjectFeature::PRIVATE
  end

  condition(:forking_allowed) do
    @subject.feature_available?(:forking, @user)
  end

  with_scope :subject
  condition(:metrics_dashboard_allowed) do
    access_allowed_to?(:metrics_dashboard)
  end

  with_scope :global
  condition(:mirror_available, score: 0) do
    ::Gitlab::CurrentSettings.current_application_settings.mirror_available
  end

  condition(:classification_label_authorized, score: 32) do
    next true if admin? || auditor? || organization_owner? # rubocop: disable Cop/UserAdmin -- this is the admin condition

    ::Gitlab::ExternalAuthorization.access_allowed?(
      @user,
      @subject.external_authorization_classification_label,
      @subject.full_path
    )
  end

  with_scope :subject
  condition(:design_management_disabled) do
    !@subject.design_management_enabled?
  end

  with_scope :subject
  condition(:service_desk_enabled) { ::ServiceDesk.enabled?(@subject) }

  condition(:model_experiments_enabled) do
    @subject.feature_available?(:model_experiments, @user)
  end

  condition(:model_registry_enabled) do
    @subject.feature_available?(:model_registry, @user)
  end

  with_scope :subject
  condition(:resource_access_token_feature_available) do
    resource_access_token_feature_available?
  end
  condition(:resource_access_token_creation_allowed) { resource_access_token_creation_allowed? }

  # We aren't checking `:read_issue` or `:read_merge_request` in this case
  # because it could be possible for a user to see an issuable-iid
  # (`:read_issue_iid` or `:read_merge_request_iid`) but then wouldn't be
  # allowed to read the actual issue after a more expensive `:read_issue`
  # check. These checks are intended to be used alongside
  # `:read_project_for_iids`.
  #
  # `:read_issue` & `:read_issue_iid` could diverge in gitlab-ee.
  condition(:issues_visible_to_user, score: 4) do
    @subject.feature_available?(:issues, @user)
  end

  condition(:merge_requests_visible_to_user, score: 4) do
    @subject.feature_available?(:merge_requests, @user)
  end

  condition(:internal_builds_disabled) do
    !@subject.builds_enabled?
  end

  condition(:user_confirmed) do
    @user && @user.confirmed?
  end

  condition(:build_service_proxy_enabled) do
    ::Feature.enabled?(:build_service_proxy, @subject)
  end

  condition(:user_defined_variables_allowed) do
    @subject.override_pipeline_variables_allowed?(team_access_level, @user)
  end

  desc "CI job token allowed to push to project, self-referential or allowlisted cross-project"
  condition(:push_repository_for_job_token_allowed) do
    next false unless @user&.from_ci_job_token?
    next false unless project.ci_push_repository_for_job_token_allowed?

    @user.ci_job_token_scope.self_referential?(project) ||
      cross_project_push_allowed_for_job_token?
  end

  condition(:packages_disabled, scope: :subject) { !@subject.packages_enabled }

  condition(:runner_registration_token_enabled, scope: :subject) { @subject.namespace.allow_runner_registration_token? }

  features = %w[
    merge_requests
    issues
    repository
    snippets
    wiki
    builds
    pages
    metrics_dashboard
    analytics
    operations
    monitor
    security_and_compliance
    environments
    feature_flags
    releases
    infrastructure
    model_experiments
  ]

  features.each do |f|
    # these are scored high because they are unlikely
    desc "Project has #{f} disabled"
    condition(:"#{f}_disabled", score: 32) { !access_allowed_to?(f.to_sym) }
  end

  condition(:project_runner_registration_allowed, scope: :subject) do
    Gitlab::CurrentSettings.valid_runner_registrars.include?('project') && @subject.runner_registration_enabled
  end

  condition :registry_enabled do
    Gitlab.config.registry.enabled
  end

  condition :packages_enabled do
    Gitlab.config.packages.enabled
  end

  condition(:dependency_proxy_enabled) do
    ::Gitlab.config.dependency_proxy.enabled
  end

  condition(:dependency_proxy_for_packages_available) do
    @subject.licensed_feature_available?(:dependency_proxy_for_packages)
  end

  condition :terraform_state_disabled do
    !Gitlab.config.terraform_state.enabled
  end

  condition(:allow_guest_plus_roles_to_pull_packages_enabled, scope: :subject) do
    Feature.enabled?(:allow_guest_plus_roles_to_pull_packages, @subject.root_ancestor)
  end

  rule { public_project }.policy do
    enable(*Authz::Role.get(:public_anonymous).direct_permissions(:project))
  end

  rule { (~anonymous & public_project) | internal_access }.policy do
    enable(*Authz::Role.get(:public_authenticated).permissions(:project))
  end

  # This is needed separate from the role YAML due to the
  # Ability.users_that_can_read_project method
  rule { guest }.enable :read_project

  rule { admin }.policy do
    enable(*Authz::Role.get(:admin).permissions(:project))
  end

  rule { project_pipeline_override_role_privileged & ~can?(:_update_privileged_pipeline_variable_override_setting) }
    .prevent :update_pipeline_variable_override_setting

  condition(:can_create_fork_in_namespace) do
    can?(:create_project_fork, project.namespace.root_ancestor)
  end

  rule { ~can_create_fork_in_namespace }.prevent :link_forked_project

  rule { internal_pages & ~anonymous & ~external_user }.policy do
    enable :read_pages_content
  end

  rule { public_pages }.policy do
    enable :read_pages_content
  end

  rule { ~can?(:create_issue) }.policy do
    prevent :create_incident
    prevent :create_task
    prevent :create_work_item
    prevent :import_issues
    prevent :import_work_items
  end

  rule { ~can?(:read_environment) }.prevent :read_freeze_period

  rule { ~forking_allowed }.prevent :fork_project

  rule { metrics_dashboard_disabled }.policy do
    prevent(:metrics_dashboard)
  end

  rule { environments_disabled }.policy do
    prevent :read_environment
    prevent :create_environment
    prevent :update_environment
    prevent :admin_environment
    prevent :destroy_environment

    prevent :read_deployment
    prevent :create_deployment
    prevent :update_deployment
    prevent :admin_deployment
    prevent :destroy_deployment
  end

  rule { feature_flags_disabled }.policy do
    prevent :read_feature_flag
    prevent :create_feature_flag
    prevent :update_feature_flag
    prevent :admin_feature_flag
    prevent :destroy_feature_flag

    prevent(:admin_feature_flags_user_lists)
    prevent(:admin_feature_flags_client)
  end

  rule { releases_disabled }.policy do
    prevent :read_release
    prevent :create_release
    prevent :update_release
    prevent :admin_release
    prevent :destroy_release
  end

  rule { monitor_disabled }.policy do
    prevent :metrics_dashboard

    prevent :read_sentry_issue
    prevent :create_sentry_issue
    prevent :update_sentry_issue
    prevent :admin_sentry_issue
    prevent :destroy_sentry_issue

    prevent :read_alert_management_alert
    prevent :create_alert_management_alert
    prevent :update_alert_management_alert
    prevent :admin_alert_management_alert
    prevent :destroy_alert_management_alert
  end

  rule { infrastructure_disabled }.policy do
    prevent :read_cluster
    prevent :create_cluster
    prevent :update_cluster
    prevent :admin_cluster
    prevent :destroy_cluster

    prevent(:read_pod_logs)
    prevent(:read_prometheus)
    prevent(:admin_project_google_cloud)
    prevent(:admin_project_aws)
  end

  rule { infrastructure_disabled | terraform_state_disabled }.policy do
    prevent :read_terraform_state
    prevent :create_terraform_state
    prevent :update_terraform_state
    prevent :admin_terraform_state
    prevent :destroy_terraform_state
    prevent :create_terraform_state_protection_rule
    prevent :delete_terraform_state_protection_rule
    prevent :update_terraform_state_protection_rule
  end

  rule { can?(:admin_terraform_state) }.policy do
    enable :create_terraform_state_protection_rule
    enable :delete_terraform_state_protection_rule
    enable :update_terraform_state_protection_rule
  end

  rule { can?(:metrics_dashboard) }.policy do
    enable :read_deployment
  end

  rule { packages_disabled }.policy do
    prevent :admin_dependency_proxy_packages_settings
    prevent :read_package
    prevent :create_package
    prevent :update_package
    prevent :admin_package
    prevent :destroy_package

    prevent :read_composer_package
    prevent :read_go_module
    prevent :read_npm_package
    prevent :read_npm_package_tag
    prevent :read_nuget_package
    prevent :read_package_pipeline
    prevent :read_pypi_package

    prevent :download_debian_package
    prevent :download_generic_package
    prevent :download_go_module
    prevent :download_helm_chart
    prevent :download_maven_package_file
    prevent :download_npm_package
    prevent :download_nuget_package
    prevent :download_pypi_package
  end

  # We need this separate rule for job tokens in case the package registry is private
  # Since read_package is enabled for a different access level than other feature based
  # permissions we cannot use the access_allowed_to dynamic conditions
  rule { ~project_allowed_for_job_token_by_scope & private_package_registry }.policy do
    prevent :read_package
    prevent :create_package
    prevent :update_package
    prevent :admin_package
    prevent :destroy_package
  end

  rule { has_project_access_or_pending_request }.prevent :request_access
  rule { ~request_access_enabled }.prevent :request_access

  rule { ~user_confirmed }.policy do
    prevent :create_build
    prevent :create_pipeline
    prevent :update_pipeline
    prevent :cancel_pipeline
    prevent :create_pipeline_schedule
  end

  rule { public_project & metrics_dashboard_allowed }.policy do
    enable :metrics_dashboard
  end

  rule { internal_access & metrics_dashboard_allowed }.policy do
    enable :metrics_dashboard
  end

  rule { (mirror_available & can?(:admin_project)) | admin }.enable :admin_remote_mirror

  rule { self_deletion_in_progress }.policy do
    prevent(*Authz::PermissionGroups::Internal.get('project:pending_deletion').permissions)
  end

  rule { (archived | deletion_scheduled) & ~self_deletion_in_progress }.policy do
    prevent(*Authz::PermissionGroups::Internal.get('project:archived').permissions)
  end

  rule { issues_disabled }.policy do
    prevent(*Authz::PermissionGroups::Internal.get('project:features:work_items').permissions)
  end

  rule { merge_requests_disabled | repository_disabled }.policy do
    prevent :approve_merge_request
    prevent :create_merge_request_in
    prevent :create_merge_request_from
    prevent :read_merge_request
    prevent :create_merge_request
    prevent :update_merge_request
    prevent :admin_merge_request
    prevent :destroy_merge_request

    prevent :read_merge_request_approval_rule
    prevent :read_merge_request_approval_state
    prevent :read_merge_request_closes_issue
    prevent :read_merge_request_commit
    prevent :read_merge_request_context_commit
    prevent :read_merge_request_diff
    prevent :read_merge_request_draft_note
    prevent :read_merge_request_merge_ref
    prevent :read_merge_request_participant
    prevent :read_merge_request_pipeline
    prevent :read_merge_request_raw_diff
    prevent :read_merge_request_related_issue
    prevent :read_merge_request_reviewer
    prevent :read_merge_request_time_statistic
  end

  rule { ~can?(:download_code) }.policy do
    prevent :create_merge_request_in
  end

  rule { pages_disabled }.policy do
    prevent :read_pages_content
    prevent :read_pages
    prevent :create_pages
    prevent :update_pages
    prevent :admin_pages
    prevent :destroy_pages
  end

  rule { issues_disabled & merge_requests_disabled }.policy do
    prevent :read_label
    prevent :create_label
    prevent :update_label
    prevent :admin_label
    prevent :destroy_label
    prevent :read_milestone
    prevent :create_milestone
    prevent :update_milestone
    prevent :admin_milestone
    prevent :destroy_milestone
    prevent :read_cycle_analytics
  end

  rule { snippets_disabled }.policy do
    prevent :read_snippet
    prevent :create_snippet
    prevent :update_snippet
    prevent :admin_snippet
    prevent :destroy_snippet
  end

  rule { analytics_disabled }.policy do
    prevent(:read_analytics)
    prevent(:read_insights)
    prevent(:read_cycle_analytics)
    prevent(:read_repository_graphs)
    prevent(:read_ci_cd_analytics)
  end

  rule { wiki_disabled }.policy do
    prevent :read_wiki
    prevent :create_wiki
    prevent :update_wiki
    prevent :admin_wiki
    prevent :destroy_wiki
    prevent :download_wiki_code
  end

  rule { download_code_deploy_token }.policy do
    enable :download_code
    enable :download_wiki_code
  end

  rule { builds_disabled | repository_disabled }.policy do
    prevent(*all_job_write_abilities)

    prevent :read_build
    prevent :create_build
    prevent :admin_build
    prevent :destroy_build
    prevent :manage_trigger
    prevent :admin_cicd_variables

    prevent :read_pipeline_schedule
    prevent :create_pipeline_schedule
    prevent :update_pipeline_schedule
    prevent :admin_pipeline_schedule
    prevent :destroy_pipeline_schedule

    prevent :read_environment
    prevent :create_environment
    prevent :update_environment
    prevent :admin_environment
    prevent :destroy_environment

    prevent :read_deployment
    prevent :create_deployment
    prevent :update_deployment
    prevent :admin_deployment
    prevent :destroy_deployment

    prevent :read_resource_group
    prevent :update_resource_group
  end

  # There's two separate cases when builds_disabled is true:
  # 1. When internal CI is disabled - builds_disabled && internal_builds_disabled
  #   - We do not prevent the user from accessing Pipelines to allow them to access external CI
  # 2. When the user is not allowed to access CI - builds_disabled && ~internal_builds_disabled
  #   - We prevent the user from accessing Pipelines
  rule { (builds_disabled & ~internal_builds_disabled) | repository_disabled }.policy do
    prevent :read_pipeline
    prevent :create_pipeline
    prevent :update_pipeline
    prevent :admin_pipeline
    prevent :destroy_pipeline
    prevent :cancel_pipeline

    prevent :read_commit_status
    prevent :create_commit_status
    prevent :destroy_commit_status
  end

  rule { repository_disabled }.policy do
    prevent :admin_tag
    prevent :build_push_code
    prevent :push_code
    prevent :read_code
    prevent :download_code
    prevent :build_download_code
    prevent :fork_project
    prevent :read_pipeline
    prevent :read_pipeline_schedule

    prevent :read_branch
    prevent :read_protected_branch
    prevent :read_protected_tag

    prevent :read_commit
    prevent :read_commit_comment
    prevent :read_commit_diff
    prevent :read_commit_merge_request
    prevent :read_commit_ref
    prevent :read_commit_sequence
    prevent :read_commit_signature

    prevent :read_repository_archive
    prevent :read_repository_blob
    prevent :read_repository_changelog
    prevent :read_repository_comparison
    prevent :read_repository_contributor
    prevent :read_repository_file
    prevent :read_repository_file_blame
    prevent :read_repository_health
    prevent :read_repository_merge_base
    prevent :read_repository_tag
    prevent :read_repository_tag_signature
    prevent :read_repository_tree

    prevent :read_feature_flag
    prevent :create_feature_flag
    prevent :update_feature_flag
    prevent :admin_feature_flag
    prevent :destroy_feature_flag
    prevent :admin_feature_flags_user_lists

    prevent :read_cluster
    prevent :create_cluster
    prevent :update_cluster
    prevent :admin_cluster
    prevent :destroy_cluster
  end

  rule { container_registry_disabled }.policy do
    prevent :build_read_container_image
    prevent :read_container_image
    prevent :create_container_image
    prevent :update_container_image
    prevent :admin_container_image
    prevent :destroy_container_image
    prevent :destroy_container_image_tag
    prevent :destroy_container_registry_protection_tag_rule
  end

  rule { anonymous & ~public_project }.prevent_all do
    # Private projects can make packages public
    # This is controlled in Packages::Policies::ProjectPolicy
    # This exception is needed since Packages::Policies::ProjectPolicy delegates to this one
    except :read_package
  end

  # If the project is private
  rule { ~project_allowed_for_job_token }.prevent_all

  rule { public_or_internal & ~project_allowed_for_job_token_by_scope }.prevent_all do
    except :build_download_code
    except :build_read_container_image
    except :read_build

    except(*::Authz::Role.get(:public_anonymous).direct_permissions(:project))
  end

  rule { ~push_repository_for_job_token_allowed }.prevent :build_push_code

  rule { ~public_builds }.policy do
    prevent :_read_public_build
    prevent :_read_public_pipeline
    prevent :_read_public_pipeline_schedule
    prevent :_read_public_ci_cd_analytics
  end

  rule { can?(:_read_public_build) }.enable :read_build
  rule { can?(:_read_public_pipeline) }.enable :read_pipeline
  rule { can?(:_read_public_pipeline_schedule) }.enable :read_pipeline_schedule
  rule { can?(:_read_public_ci_cd_analytics) }.enable :read_ci_cd_analytics

  # Allow upstream developers to create pipelines on a fork when the fork has
  # an open MR with "Allow commits from members who can merge to the target
  # branch" enabled.
  rule { (public_project | internal_access) & has_merge_requests_allowing_pushes }.policy do
    enable :create_build
    enable :create_pipeline
  end

  rule do
    (can?(:read_project_for_iids) & issues_visible_to_user) | can?(:read_issue)
  end.enable :read_issue_iid

  rule { ~merge_requests_visible_to_user }.prevent :read_merge_request_iid

  rule { external_authorization_enabled & ~classification_label_authorized }.prevent_all do
    # Preventing access here still allows the projects to be listed. Listing
    # projects doesn't check the `:read_project` ability. But instead counts
    # on the `project_authorizations` table.
    #
    # All other actions should explicitly check read project, which would
    # trigger the `classification_label_authorized` condition.
    #
    # read_project_for_iids, read_issue_iid, and read_merge_request_iid are not prevented
    # by this condition, as they are used for cross-project reference checks.
    except :read_project_for_iids
    except :read_issue_iid
    except :read_merge_request_iid
  end

  rule { blocked }.policy do
    prevent :create_pipeline
  end

  rule { can?(:read_issue) }.policy do
    enable :read_design
    enable :read_design_activity
    enable :read_issue_link
    enable :read_work_item
  end

  rule { can?(:read_merge_request) }.policy do
    enable :read_vulnerability_merge_request_link
  end

  # Design abilities could also be prevented in the issue policy.
  rule { design_management_disabled }.policy do
    prevent :read_design
    prevent :read_design_activity
    prevent :create_design
    prevent :update_design
    prevent :destroy_design
    prevent :move_design
  end

  rule { download_code_deploy_key }.policy do
    enable :download_code
    enable :read_code
  end

  rule { push_code_deploy_key }.policy do
    enable :admin_tag
    enable :push_code
  end

  rule { read_container_image_deploy_token }.policy do
    enable :read_container_image
  end

  rule { create_container_image_deploy_token }.policy do
    enable :create_container_image
  end

  rule { read_package_registry_deploy_token }.policy do
    enable :read_package
    enable :read_project
    enable :_read_dependency_proxy_package
  end

  rule { write_package_registry_deploy_token }.policy do
    enable :create_package
    enable :read_package
    enable :destroy_package
    enable :read_project
    enable :_read_dependency_proxy_package
  end

  rule { ~can?(:create_pipeline) }.prevent :create_web_ide_terminal

  rule { build_service_proxy_enabled }.enable :build_service_proxy_enabled

  rule { can?(:download_code) }.policy do
    enable :read_repository_graphs
  end

  rule { can?(:read_build) & can?(:read_pipeline) }.policy do
    enable :read_build_report_results
  end

  rule { support_bot & ~service_desk_enabled }.prevent_all

  rule { ~service_desk_enabled }.prevent :create_ticket

  rule { project_bot }.enable :project_bot_access

  rule { ~resource_access_token_feature_available }.policy do
    prevent :read_resource_access_tokens
    prevent :destroy_resource_access_tokens
    prevent :create_resource_access_tokens
    prevent :manage_resource_access_tokens
  end

  rule { ~resource_access_token_creation_allowed }.policy do
    prevent :create_resource_access_tokens
    prevent :manage_resource_access_tokens
  end

  rule { can?(:project_bot_access) }.policy do
    prevent :create_resource_access_tokens
    prevent :manage_resource_access_tokens
  end

  rule { user_defined_variables_allowed }.policy do
    enable :set_pipeline_variables
  end

  rule { security_and_compliance_disabled }.policy do
    prevent :access_security_and_compliance
    prevent :admin_vulnerability
    prevent :read_compliance_framework
    prevent :read_vulnerability
    prevent :update_vulnerability_flag
    prevent :read_security_configuration
    prevent :read_security_settings
    prevent :update_security_setting
    prevent :update_sec_ai_workflow_settings
    prevent :read_project_security_dashboard
    prevent :read_security_resource
    prevent :read_security_inventory
    prevent :admin_security_attributes
    prevent :read_security_orchestration_policies
    prevent :modify_security_policy
    prevent :read_compliance_dashboard
    prevent :read_compliance_adherence_report
    prevent :read_compliance_violations_report
    prevent :read_project_security_exclusions
    prevent :manage_project_security_exclusions
    prevent :read_security_scan_profiles
    prevent :apply_security_scan_profiles
    prevent :read_secret_push_protection_info
    prevent :enable_secret_push_protection
    prevent :enable_container_scanning_for_registry
    prevent :update_cvs_for_container_scanning
    prevent :update_cvs_for_dependency_scanning
    prevent :read_on_demand_dast_scan
    prevent :create_on_demand_dast_scan
    prevent :edit_on_demand_dast_scan
    prevent :update_on_demand_dast_scan
    prevent :_create_dast_pipeline
    prevent :_run_dast_pipeline
    prevent :admin_vulnerability_external_issue_link
    prevent :admin_vulnerability_issue_link
    prevent :create_vulnerability_export
    prevent :create_vulnerability_archive_export
    prevent :read_security_project_tracked_ref
    prevent :read_audit_event
    prevent :read_any_audit_event
  end

  rule { ~admin & ~organization_owner & ~project_runner_registration_allowed }.policy do
    prevent :create_runners
  end

  rule { ~runner_registration_token_enabled }.policy do
    prevent :read_runners_registration_token
    prevent :update_runners_registration_token
  end

  rule { registry_enabled & can?(:admin_container_image) }.policy do
    enable :view_package_registry_project_settings
  end

  rule { packages_enabled & can?(:admin_package) }.policy do
    enable :view_package_registry_project_settings
  end

  rule { ~packages_enabled }.prevent :admin_dependency_proxy_packages_settings
  rule { ~dependency_proxy_enabled }.prevent :admin_dependency_proxy_packages_settings
  rule { ~dependency_proxy_for_packages_available }.prevent :admin_dependency_proxy_packages_settings

  rule { can?(:read_project) }.policy do
    enable :read_incident_management_timeline_event_tag
    enable :read_project_metadata
  end

  rule { public_project & model_registry_enabled }.policy do
    enable :read_model_registry
  end

  rule { ~public_project & guest & model_registry_enabled }.policy do
    enable :read_model_registry
  end

  rule { ~model_registry_enabled }.prevent :write_model_registry

  rule { public_project & model_experiments_enabled }.policy do
    enable :read_model_experiments
  end

  rule { ~public_project & guest & model_experiments_enabled }.policy do
    enable :read_model_experiments
  end

  rule { ~model_experiments_enabled }.prevent :write_model_experiments

  rule { ~private_project & guest & external_user }.policy do
    enable :read_container_image
    enable :build_read_container_image
  end

  rule { can?(:create_pipeline_schedule) }.policy do
    enable :read_ci_pipeline_schedules_plan_limit
  end

  # TODO: Remove this rule and move :read_package permission from
  # reporter to guest with the rollout of the FF allow_guest_plus_roles_to_pull_packages
  # https://gitlab.com/gitlab-org/gitlab/-/issues/512210
  rule { guest & allow_guest_plus_roles_to_pull_packages_enabled }.enable :read_package

  rule { can?(:read_project) }.enable :read_attestation

  private

  def team_member?
    return false if @user.nil?
    return false unless user_is_user?

    greedy_load_subject = false

    # when scoping by subject, we want to be greedy
    # and load *all* the members with one query.
    greedy_load_subject ||= DeclarativePolicy.preferred_scope == :subject

    # in this case we're likely to have loaded #members already
    # anyways, and #member? would fail with an error
    greedy_load_subject ||= !@user.persisted?

    if greedy_load_subject
      # We want to load all the members with one query. Calling #include? on
      # project.team.members will perform a separate query for each user, unless
      # project.team.members was loaded before somewhere else. Calling #to_a
      # ensures it's always loaded before checking for membership.
      project.team.members.to_a.include?(user)
    else
      # otherwise we just make a specific query for
      # this particular user.
      team_access_level >= Gitlab::Access::GUEST
    end
  end

  def project_group_member?
    return false if @user.nil?
    return false unless user_is_user?

    project.group && project.group.member?(@user)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def project_group_requester?
    return false if @user.nil?
    return false unless user_is_user?

    project.group && project.group.requesters.exists?(user_id: @user.id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def team_access_level
    return -1 if @user.nil?
    return -1 unless user_is_user?

    @team_access_level ||= lookup_access_level!
  end
  alias_method :access_level, :team_access_level

  def lookup_access_level!
    return ::Gitlab::Access::REPORTER if alert_bot? || support_bot?

    # NOTE: max_member_access_for_user is cached
    project.max_member_access_for_user(@user)
  end

  def access_allowed_to?(feature)
    return false unless project.project_feature

    case project.project_feature.access_level(feature)
    when ProjectFeature::DISABLED
      false
    when ProjectFeature::PRIVATE
      return false unless project_allowed_for_job_token_by_scope?

      can?(:read_all_resources) ||
        can?(:read_all_organization_resources) ||
        team_access_level >= ProjectFeature.required_minimum_access_level(feature)
    else
      true
    end
  end

  def resource_access_token_feature_available?
    true
  end

  def resource_access_token_create_feature_available?
    true
  end

  def resource_access_token_creation_allowed?
    group = project.group

    return true unless group # always enable for projects in personal namespaces

    resource_access_token_create_feature_available? && group.root_ancestor.namespace_settings.resource_access_token_creation_allowed?
  end

  def cross_project_push_allowed_for_job_token?
    project.ci_cross_project_push_for_job_token_allowed? &&
      project.ci_inbound_job_token_scope_enabled? &&
      @user.ci_job_token_scope.policies_allowed?(project, [:admin_repositories])
  end

  def project
    @subject
  end
end

ProjectPolicy.prepend_mod_with('ProjectPolicy')
