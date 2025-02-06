# frozen_string_literal: true

class ProjectPolicy < BasePolicy
  include CrudPolicyHelpers
  include ArchivedAbilities

  desc "Project has public builds enabled"
  condition(:public_builds, scope: :subject, score: 0) { project.public_builds? }

  # For guest access we use #team_member? so we can use
  # project.members, which gets cached in subject scope.
  # This is safe because team_access_level is guaranteed
  # by ProjectAuthorization's validation to be at minimum
  # GUEST
  desc "User has guest access"
  condition(:guest) { team_member? }

  # This is not a linear condition (some policies available for planner might not be available for higher access levels)
  desc "User has planner access"
  condition(:planner) { team_access_level == Gitlab::Access::PLANNER }

  desc "User has reporter access"
  condition(:reporter) { team_access_level >= Gitlab::Access::REPORTER }

  desc "User has developer access"
  condition(:developer) { team_access_level >= Gitlab::Access::DEVELOPER }

  desc "User has maintainer access"
  condition(:maintainer) { team_access_level >= Gitlab::Access::MAINTAINER }

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
    project.internal? && !user.external?
  end

  desc "User owns the project's organization"
  condition(:organization_owner) do
    owns_project_organization?
  end

  rule { admin | organization_owner }.enable :read_all_organization_resources

  desc "User is a member of the group"
  condition(:group_member, scope: :subject) { project_group_member? }

  desc "User is a requester of the group"
  condition(:group_requester, scope: :subject) { project_group_requester? }

  desc "User is external"
  condition(:external_user) { user.external? }

  desc "Project is archived"
  condition(:archived, scope: :subject, score: 0) { project.archived? }

  desc "Project user pipeline variables minimum override role"
  condition(:project_pipeline_override_role_owner) { project.ci_pipeline_variables_minimum_override_role == 'owner' }

  desc "Project is in the process of being deleted"
  condition(:pending_delete) { project.pending_delete? }

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

  desc "Container registry is enabled for everyone with access to the project"
  condition(:container_registry_enabled_for_everyone_with_access, scope: :subject) do
    project.container_registry_access_level == ProjectFeature::ENABLED
  end

  desc "Project has an external wiki"
  condition(:has_external_wiki, scope: :subject, score: 0) { project.has_external_wiki? }

  desc "Project has request access enabled"
  condition(:request_access_enabled, scope: :subject, score: 0) { project.request_access_enabled }

  desc "Has merge requests allowing pushes to user"
  condition(:has_merge_requests_allowing_pushes) do
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

  desc "Deploy token with read access"
  condition(:download_code_deploy_token) do
    user.is_a?(DeployToken) && user.has_access_to?(project)
  end

  desc "If user is authenticated via CI job token then the target project should be in scope"
  condition(:project_allowed_for_job_token_by_scope) do
    !@user&.from_ci_job_token? || @user.ci_job_token_scope.accessible?(project)
  end

  desc "Public, internal or project in the scope allowed via CI job token"
  condition(:project_allowed_for_job_token) do
    public_project? || internal_access? || project_allowed_for_job_token_by_scope?
  end

  desc "If the user is via CI job token and project container registry visibility allows access"
  condition(:job_token_container_registry) { job_token_access_allowed_to?(:container_registry) }

  desc "If the user is via CI job token and project package registry visibility allows access"
  condition(:job_token_package_registry) { job_token_access_allowed_to?(:package_registry) }

  desc "If the user is via CI job token and project ci/cd visibility allows access"
  condition(:job_token_builds) { job_token_access_allowed_to?(:builds) }

  desc "If the user is via CI job token and project releases visibility allows access"
  condition(:job_token_releases) { job_token_access_allowed_to?(:releases) }

  desc "If the user is via CI job token and project environment visibility allows access"
  condition(:job_token_environments) { job_token_access_allowed_to?(:environments) }

  desc "If the project is either public or internal"
  condition(:public_or_internal) do
    project.public? || project.internal?
  end

  with_scope :subject
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

  with_scope :subject
  condition(:classification_label_authorized, score: 32) do
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

  with_scope :subject
  condition(:model_experiments_enabled) do
    @subject.feature_available?(:model_experiments, @user)
  end

  with_scope :subject
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

  condition(:user_confirmed?) do
    @user && @user.confirmed?
  end

  condition(:build_service_proxy_enabled) do
    ::Feature.enabled?(:build_service_proxy, @subject)
  end

  condition(:user_defined_variables_allowed) do
    @subject.override_pipeline_variables_allowed?(team_access_level)
  end

  condition(:push_repository_for_job_token_allowed) do
    if ::Feature.enabled?(:allow_push_repository_for_job_token, @subject)
      @user&.from_ci_job_token? && project.ci_push_repository_for_job_token_allowed? && @user.ci_job_token_scope.self_referential?(project)
    else
      false
    end
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

  condition :terraform_state_disabled do
    !Gitlab.config.terraform_state.enabled
  end

  condition(:namespace_catalog_available) { namespace_catalog_available? }

  condition(:created_and_owned_by_banned_user, scope: :subject) do
    Feature.enabled?(:hide_projects_of_banned_users) && @subject.created_and_owned_by_banned_user?
  end

  desc "User has either planner or reporter access"
  condition(:planner_or_reporter_access) do
    can?(:reporter_access) || can?(:planner_access)
  end

  condition(:allow_guest_plus_roles_to_pull_packages_enabled, scope: :subject) do
    Feature.enabled?(:allow_guest_plus_roles_to_pull_packages, @subject.root_ancestor)
  end

  # `:read_project` may be prevented in EE, but `:read_project_for_iids` should
  # not.
  rule { guest | admin | organization_owner }.enable :read_project_for_iids

  rule { admin }.enable :update_max_artifacts_size
  rule { admin }.enable :read_storage_disk_path
  rule { can?(:read_all_resources) }.enable :read_confidential_issues

  rule { guest }.enable :guest_access
  rule { planner }.enable :planner_access
  rule { reporter }.enable :reporter_access
  rule { developer }.enable :developer_access
  rule { maintainer }.enable :maintainer_access
  rule { owner | admin | organization_owner }.enable :owner_access

  rule { project_pipeline_override_role_owner & ~can?(:owner_access) }.prevent :change_restrict_user_defined_variables

  rule { can?(:owner_access) }.policy do
    enable :guest_access
    enable :planner_access
    enable :reporter_access
    enable :developer_access
    enable :maintainer_access

    enable :change_namespace
    enable :change_visibility_level
    enable :remove_project
    enable :archive_project
    enable :link_forked_project
    enable :remove_fork_project
    enable :destroy_merge_request
    enable :destroy_issue

    enable :set_issue_iid
    enable :set_issue_created_at
    enable :set_issue_updated_at
    enable :set_note_created_at
    enable :set_emails_disabled
    enable :set_show_default_award_emojis
    enable :set_show_diff_preview_in_email
    enable :set_warn_about_potentially_unwanted_characters
    enable :manage_owners

    enable :add_catalog_resource

    enable :destroy_pipeline
  end

  rule { can?(:guest_access) }.policy do
    enable :read_project
    enable :read_issue_board
    enable :read_issue_board_list
    enable :read_wiki
    enable :read_issue
    enable :read_label
    enable :read_milestone
    enable :read_snippet
    enable :read_project_member
    enable :read_note
    enable :create_project
    enable :create_issue
    enable :create_note
    enable :upload_file
    enable :read_cycle_analytics
    enable :award_emoji
    enable :read_pages_content
    enable :read_release
    enable :read_analytics
    enable :read_insights
    enable :read_upload
  end

  rule { can?(:planner_access) }.policy do
    enable :guest_access
    enable :admin_issue_board
    enable :admin_issue_board_list
    enable :update_issue
    enable :reopen_issue
    enable :admin_issue
    enable :admin_work_item
    enable :destroy_issue
    enable :read_confidential_issues
    enable :create_design
    enable :update_design
    enable :move_design
    enable :destroy_design
    enable :admin_label
    enable :admin_milestone
    enable :download_wiki_code
    enable :create_wiki
    enable :admin_wiki
    enable :read_merge_request
    enable :export_work_items
  end

  rule { can?(:reporter_access) & can?(:create_issue) }.enable :create_incident

  rule { can?(:reporter_access) & can?(:read_environment) }.enable :read_freeze_period

  rule { can?(:create_issue) }.enable :create_work_item

  rule { can?(:create_issue) }.enable :create_task

  # These abilities are not allowed to admins that are not members of the project,
  # that's why they are defined separately.
  rule { guest & can?(:download_code) }.enable :build_download_code
  rule { guest & can?(:read_container_image) }.enable :build_read_container_image

  rule { guest & ~public_project }.enable :read_grafana

  rule { can?(:reporter_access) }.policy do
    enable :admin_issue_board
    enable :download_code
    enable :read_statistics
    enable :daily_statistics
    enable :download_wiki_code
    enable :create_snippet
    enable :update_issue
    enable :reopen_issue
    enable :admin_issue
    enable :admin_work_item
    enable :admin_label
    enable :admin_milestone
    enable :admin_issue_board_list
    enable :read_commit_status
    enable :read_build
    enable :read_container_image
    enable :read_harbor_registry
    enable :read_deploy_board
    enable :read_pipeline
    enable :read_pipeline_schedule
    enable :read_environment
    enable :read_deployment
    enable :read_merge_request
    enable :read_sentry_issue
    enable :read_prometheus
    enable :metrics_dashboard
    enable :read_confidential_issues
    enable :read_package
    enable :read_ci_cd_analytics
    enable :read_external_emails
    enable :read_grafana
    enable :export_work_items
    enable :create_design
    enable :update_design
    enable :move_design
    enable :destroy_design
  end

  # We define `:public_user_access` separately because there are cases in gitlab-ee
  # where we enable or prevent it based on other coditions.
  rule { (~anonymous & public_project) | internal_access }.policy do
    enable :public_user_access
    enable :read_project_for_iids
  end

  rule { can?(:public_user_access) }.policy do
    enable :public_access
    enable :guest_access

    enable :build_download_code
    enable :request_access
  end

  rule { container_registry_enabled_for_everyone_with_access & can?(:public_user_access) }.policy do
    enable :build_read_container_image
  end

  rule { (can?(:public_user_access) | can?(:reporter_access)) & forking_allowed }.policy do
    enable :fork_project
  end

  rule { metrics_dashboard_disabled }.policy do
    prevent(:metrics_dashboard)
  end

  rule { environments_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:environment))
    prevent(*create_read_update_admin_destroy(:deployment))
  end

  rule { feature_flags_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:feature_flag))
    prevent(:admin_feature_flags_user_lists)
    prevent(:admin_feature_flags_client)
  end

  rule { releases_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:release))
  end

  rule { monitor_disabled }.policy do
    prevent(:metrics_dashboard)
    prevent(*create_read_update_admin_destroy(:sentry_issue))
    prevent(*create_read_update_admin_destroy(:alert_management_alert))
  end

  rule { infrastructure_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:cluster))
    prevent(:read_pod_logs)
    prevent(:read_prometheus)
    prevent(:admin_project_google_cloud)
    prevent(:admin_project_aws)
  end

  rule { infrastructure_disabled | terraform_state_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:terraform_state))
  end

  rule { can?(:metrics_dashboard) }.policy do
    enable :read_deployment
  end

  rule { packages_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:package))
  end

  rule { owner | admin | organization_owner | guest | group_member | group_requester }.prevent :request_access
  rule { ~request_access_enabled }.prevent :request_access

  rule { (can?(:planner_access) | can?(:developer_access)) & can?(:create_issue) }.enable :import_issues
  rule { planner_or_reporter_access & can?(:create_work_item) }.enable :import_work_items

  rule { can?(:developer_access) }.policy do
    enable :create_package
    enable :admin_issue_board
    enable :admin_merge_request
    enable :update_merge_request
    enable :reopen_merge_request
    enable :create_commit_status
    enable :update_commit_status
    enable :create_build
    enable :update_build
    enable :cancel_build
    enable :read_resource_group
    enable :update_resource_group
    enable :create_merge_request_from
    enable :create_wiki
    enable :push_code
    enable :resolve_note
    enable :create_container_image
    enable :update_container_image
    enable :destroy_container_image
    enable :create_environment
    enable :update_environment
    enable :destroy_environment
    enable :create_deployment
    enable :update_deployment
    enable :read_cluster # Deprecated as certificate-based cluster integration (`Clusters::Cluster`).
    enable :read_cluster_agent
    enable :use_k8s_proxies
    enable :create_release
    enable :update_release
    enable :destroy_release
    enable :publish_catalog_version
    enable :read_alert_management_alert
    enable :update_alert_management_alert
    enable :read_terraform_state
    enable :read_pod_logs
    enable :read_feature_flag
    enable :create_feature_flag
    enable :update_feature_flag
    enable :destroy_feature_flag
    enable :admin_feature_flag
    enable :admin_feature_flags_user_lists
    enable :update_escalation_status
    enable :read_secure_files
    enable :update_sentry_issue
  end

  rule { can?(:developer_access) & user_confirmed? }.policy do
    enable :create_pipeline
    enable :update_pipeline
    enable :cancel_pipeline
    enable :create_pipeline_schedule
  end

  rule { can?(:maintainer_access) }.policy do
    enable :destroy_package
    enable :admin_package
    enable :admin_issue_board
    enable :push_to_delete_protected_branch
    enable :update_snippet
    enable :admin_snippet
    enable :rename_project
    enable :admin_project_member
    enable :admin_note
    enable :admin_wiki
    enable :admin_project
    enable :admin_integrations
    enable :admin_commit_status
    enable :admin_build
    enable :admin_container_image
    enable :admin_pipeline
    enable :admin_environment
    enable :admin_deployment
    enable :destroy_deployment
    enable :admin_pages
    enable :read_pages
    enable :update_pages
    enable :remove_pages
    enable :add_cluster
    enable :create_cluster
    enable :update_cluster
    enable :admin_cluster
    enable :create_environment_terminal
    enable :destroy_release
    enable :destroy_artifacts
    enable :admin_operations
    enable :admin_sentry
    enable :read_deploy_token
    enable :create_deploy_token
    enable :destroy_deploy_token
    enable :admin_terraform_state
    enable :create_freeze_period
    enable :read_freeze_period
    enable :update_freeze_period
    enable :destroy_freeze_period
    enable :admin_feature_flags_client
    enable :register_project_runners
    enable :create_runner
    enable :admin_project_runners
    enable :read_project_runners
    enable :update_runners_registration_token
    enable :admin_project_google_cloud
    enable :admin_project_aws
    enable :admin_secure_files
    enable :admin_upload
    enable :destroy_upload
    enable :admin_incident_management_timeline_event_tag
    enable :stop_environment
    enable :read_import_error
    enable :admin_cicd_variables
    enable :admin_push_rules
    enable :admin_runner
    enable :manage_deploy_tokens
    enable :manage_merge_request_settings
    enable :manage_protected_tags
    enable :change_restrict_user_defined_variables
    enable :create_protected_branch
    enable :admin_protected_branch
    enable :admin_protected_environments
  end

  rule { can?(:manage_protected_tags) }.policy do
    enable :read_protected_tags
    enable :create_protected_tags
    enable :update_protected_tags
    enable :destroy_protected_tags
  end

  rule { can?(:admin_build) }.enable :manage_trigger
  rule { can?(:admin_runner) }.enable :read_runner

  rule { public_project & metrics_dashboard_allowed }.policy do
    enable :metrics_dashboard
  end

  rule { internal_access & metrics_dashboard_allowed }.policy do
    enable :metrics_dashboard
  end

  rule { (mirror_available & can?(:admin_project)) | admin }.enable :admin_remote_mirror
  rule { can?(:push_code) }.enable :admin_tag

  rule { archived }.policy do
    prevent(*archived_abilities)

    archived_features.each do |feature|
      prevent(*create_update_admin(feature))
    end
  end

  rule { archived & ~pending_delete }.policy do
    archived_features.each do |feature|
      prevent(:"destroy_#{feature}")
    end
  end

  rule { issues_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:issue))
    prevent(*create_read_update_admin_destroy(:issue_board))
    prevent(*create_read_update_admin_destroy(:issue_board_list))
  end

  rule { merge_requests_disabled | repository_disabled }.policy do
    prevent :create_merge_request_in
    prevent :create_merge_request_from
    prevent(*create_read_update_admin_destroy(:merge_request))
  end

  rule { ~can?(:download_code) }.policy do
    prevent :create_merge_request_in
  end

  rule { pages_disabled }.policy do
    prevent :read_pages_content
    prevent(*create_read_update_admin_destroy(:pages))
  end

  rule { issues_disabled & merge_requests_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:label))
    prevent(*create_read_update_admin_destroy(:milestone))
    prevent(:read_cycle_analytics)
  end

  rule { snippets_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:snippet))
  end

  rule { analytics_disabled }.policy do
    prevent(:read_analytics)
    prevent(:read_insights)
    prevent(:read_cycle_analytics)
    prevent(:read_repository_graphs)
    prevent(:read_ci_cd_analytics)
  end

  rule { wiki_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:wiki))
    prevent(:download_wiki_code)
  end

  rule { download_code_deploy_token }.policy do
    enable :download_wiki_code
  end

  rule { builds_disabled | repository_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:build))
    prevent :cancel_build
    prevent(*create_read_update_admin_destroy(:pipeline_schedule))
    prevent(*create_read_update_admin_destroy(:environment))
    prevent(*create_read_update_admin_destroy(:deployment))
  end

  # There's two separate cases when builds_disabled is true:
  # 1. When internal CI is disabled - builds_disabled && internal_builds_disabled
  #   - We do not prevent the user from accessing Pipelines to allow them to access external CI
  # 2. When the user is not allowed to access CI - builds_disabled && ~internal_builds_disabled
  #   - We prevent the user from accessing Pipelines
  rule { (builds_disabled & ~internal_builds_disabled) | repository_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:pipeline))
    prevent :cancel_pipeline
    prevent(*create_read_update_admin_destroy(:commit_status))
  end

  rule { repository_disabled }.policy do
    prevent :build_push_code
    prevent :push_code
    prevent :download_code
    prevent :build_download_code
    prevent :fork_project
    prevent :read_commit_status
    prevent :read_pipeline
    prevent :read_pipeline_schedule
    prevent(*create_read_update_admin_destroy(:feature_flag))
    prevent(:admin_feature_flags_user_lists)
    prevent(*create_read_update_admin_destroy(:cluster))
  end

  rule { container_registry_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:container_image))
  end

  rule { anonymous & ~public_project }.prevent_all

  rule { public_project }.policy do
    enable :public_access
    enable :read_project_for_iids
  end

  # If the project is private
  rule { ~project_allowed_for_job_token }.prevent_all

  # If this project is public or internal we want to prevent all aside from a few public policies
  rule { public_or_internal & ~project_allowed_for_job_token_by_scope }.policy do
    prevent :guest_access
    prevent :planner_access
    prevent :public_access
    prevent :reporter_access
    prevent :developer_access
    prevent :maintainer_access
    prevent :owner_access
  end

  rule { public_project & ~project_allowed_for_job_token_by_scope }.policy do
    prevent :public_user_access
  end

  rule { can?(:developer_access) & push_repository_for_job_token_allowed }.policy do
    enable :build_push_code
  end

  rule { public_or_internal & job_token_container_registry }.policy do
    enable :build_read_container_image
    enable :read_container_image
  end

  rule { public_or_internal & job_token_package_registry }.policy do
    enable :read_package
    enable :read_project
  end

  rule { public_or_internal & job_token_builds }.policy do
    enable :read_commit_status # this is additionally needed to download artifacts
  end

  rule { public_or_internal & job_token_releases }.policy do
    enable :read_release
  end

  rule { public_or_internal & job_token_environments }.policy do
    enable :read_environment
  end

  rule { can?(:public_access) }.policy do
    enable :read_package
    enable :read_project
    enable :read_issue_board
    enable :read_issue_board_list
    enable :read_wiki
    enable :read_label
    enable :read_milestone
    enable :read_snippet
    enable :read_project_member
    enable :read_merge_request
    enable :read_note
    enable :read_pipeline
    enable :read_environment
    enable :read_deployment
    enable :read_commit_status
    enable :read_container_image
    enable :download_code
    enable :read_release
    enable :download_wiki_code
    enable :read_cycle_analytics
    enable :read_pages_content
    enable :read_analytics
    enable :read_insights
    enable :read_upload

    # NOTE: may be overridden by IssuePolicy
    enable :read_issue
  end

  rule { can?(:public_access) & public_builds }.policy do
    enable :read_ci_cd_analytics
    enable :read_pipeline_schedule
  end

  rule { public_builds }.policy do
    enable :read_build
  end

  rule { public_builds & can?(:guest_access) }.policy do
    enable :read_pipeline
    enable :read_pipeline_schedule
  end

  # These rules are included to allow maintainers of projects to push to certain
  # to run pipelines for the branches they have access to.
  rule { can?(:public_access) & has_merge_requests_allowing_pushes & user_confirmed? }.policy do
    enable :create_build
    enable :create_pipeline
  end

  rule do
    (can?(:read_project_for_iids) & issues_visible_to_user) | can?(:read_issue)
  end.enable :read_issue_iid

  rule do
    (~guest & can?(:read_project_for_iids) & merge_requests_visible_to_user) | can?(:read_merge_request)
  end.enable :read_merge_request_iid

  rule { ~can?(:read_cross_project) & ~classification_label_authorized }.policy do
    # Preventing access here still allows the projects to be listed. Listing
    # projects doesn't check the `:read_project` ability. But instead counts
    # on the `project_authorizations` table.
    #
    # All other actions should explicitly check read project, which would
    # trigger the `classification_label_authorized` condition.
    #
    # `:read_project_for_iids` is not prevented by this condition, as it is
    # used for cross-project reference checks.
    prevent :guest_access
    prevent :planner_access
    prevent :public_access
    prevent :public_user_access
    prevent :reporter_access
    prevent :developer_access
    prevent :maintainer_access
    prevent :owner_access
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

  rule { can?(:developer_access) }.policy do
    enable :read_security_configuration
  end

  rule { can?(:guest_access) & can?(:download_code) }.policy do
    enable :create_merge_request_in
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
  end

  rule { push_code_deploy_key }.policy do
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
  end

  rule { write_package_registry_deploy_token }.policy do
    enable :create_package
    enable :read_package
    enable :destroy_package
    enable :read_project
  end

  rule { can?(:create_pipeline) & can?(:maintainer_access) }.enable :create_web_ide_terminal

  rule { build_service_proxy_enabled }.enable :build_service_proxy_enabled

  rule { can?(:download_code) }.policy do
    enable :read_repository_graphs
  end

  rule { can?(:read_build) & can?(:read_pipeline) }.policy do
    enable :read_build_report_results
  end

  rule { support_bot }.enable :guest_access
  rule { support_bot & ~service_desk_enabled }.policy do
    prevent :create_note
    prevent :read_project
    prevent :guest_access
  end

  rule { project_bot }.enable :project_bot_access

  rule { can?(:read_all_resources) & resource_access_token_feature_available }.enable :read_resource_access_tokens

  rule { can?(:admin_project) & resource_access_token_feature_available }.policy do
    enable :read_resource_access_tokens
    enable :destroy_resource_access_tokens
  end

  rule { can?(:admin_project) & resource_access_token_feature_available & resource_access_token_creation_allowed }.policy do
    enable :create_resource_access_tokens
    enable :manage_resource_access_tokens
  end

  rule { can?(:admin_project) }.policy do
    enable :read_usage_quotas
    enable :view_edit_page
    enable :read_web_hook
    enable :admin_web_hook
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
  end

  rule { can?(:developer_access) }.policy do
    enable :access_security_and_compliance
  end

  rule { ~admin & ~organization_owner & ~project_runner_registration_allowed }.policy do
    prevent :register_project_runners
    prevent :create_runner
  end

  rule { ~runner_registration_token_enabled }.policy do
    prevent :register_project_runners
    prevent :update_runners_registration_token
  end

  rule { can?(:admin_project_member) }.policy do
    enable :import_project_members_from_another_project
    # ability to read, approve or reject member access requests of other users
    enable :admin_member_access_request
    enable :read_member_access_request
  end

  rule { registry_enabled & can?(:admin_container_image) }.policy do
    enable :view_package_registry_project_settings
  end

  rule { packages_enabled & can?(:admin_package) }.policy do
    enable :view_package_registry_project_settings
  end

  rule { can?(:read_project) }.policy do
    enable :read_incident_management_timeline_event_tag
  end

  rule { can?(:download_code) }.policy do
    enable :read_code
  end

  # Should be matched with GroupPolicy#read_internal_note
  rule { admin | planner_or_reporter_access }.enable :read_internal_note

  rule { can?(:developer_access) & namespace_catalog_available }.policy do
    enable :read_namespace_catalog
  end

  rule { public_project & model_registry_enabled }.policy do
    enable :read_model_registry
  end

  rule { ~public_project & guest & model_registry_enabled }.policy do
    enable :read_model_registry
  end

  rule { developer & model_registry_enabled }.policy do
    enable :write_model_registry
  end

  rule { public_project & model_experiments_enabled }.policy do
    enable :read_model_experiments
  end

  rule { ~public_project & guest & model_experiments_enabled }.policy do
    enable :read_model_experiments
  end

  rule { developer & model_experiments_enabled }.policy do
    enable :write_model_experiments
  end

  rule { ~admin & ~organization_owner & created_and_owned_by_banned_user }.policy do
    prevent :read_project
  end

  rule { ~private_project & guest & external_user }.enable :read_container_image

  rule { can?(:create_pipeline_schedule) }.policy do
    enable :read_ci_pipeline_schedules_plan_limit
  end

  # TODO: Remove this rule and move :read_package permission from
  # can?(:reporter_access) to can?(:guest_access)
  # with the rollout of the FF allow_guest_plus_roles_to_pull_packages
  # https://gitlab.com/gitlab-org/gitlab/-/issues/512210
  rule { can?(:guest_access) & allow_guest_plus_roles_to_pull_packages_enabled }.enable :read_package

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

  # rubocop:disable Cop/UserAdmin -- specifically check the admin attribute
  def owns_project_organization?
    return false unless @user
    return false unless user_is_user?
    return false unless @subject.organization
    # Ensure admins can't bypass admin mode.
    return false if @user.admin? && !can?(:admin)

    # Load the owners with a single query.
    @subject.organization
            .owner_user_ids
            .include?(@user.id)
  end
  # rubocop:enable Cop/UserAdmin

  def team_access_level
    return -1 if @user.nil?
    return -1 unless user_is_user?

    @team_access_level ||= lookup_access_level!
  end

  def lookup_access_level!
    return ::Gitlab::Access::REPORTER if alert_bot?
    return ::Gitlab::Access::REPORTER if support_bot? && service_desk_enabled?

    # NOTE: max_member_access has its own cache
    project.team.max_member_access(@user.id)
  end

  def access_allowed_to?(feature)
    return false unless project.project_feature

    case project.project_feature.access_level(feature)
    when ProjectFeature::DISABLED
      false
    when ProjectFeature::PRIVATE
      can?(:read_all_resources) ||
        can?(:read_all_organization_resources) ||
        team_access_level >= ProjectFeature.required_minimum_access_level(feature)
    else
      true
    end
  end

  def job_token_access_allowed_to?(feature)
    return false unless @user&.from_ci_job_token?
    return false unless project.project_feature

    case project.project_feature.access_level(feature)
    when ProjectFeature::DISABLED
      false
    when ProjectFeature::PRIVATE
      @user.ci_job_token_scope.accessible?(project)
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

  def project
    @subject
  end

  def namespace_catalog_available?
    false
  end
end

ProjectPolicy.prepend_mod_with('ProjectPolicy')
