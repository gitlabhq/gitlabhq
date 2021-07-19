# frozen_string_literal: true

class ProjectPolicy < BasePolicy
  include CrudPolicyHelpers
  include ReadonlyAbilities

  desc "User is a project owner"
  condition :owner do
    (project.owner.present? && project.owner == @user) ||
      project.group&.has_owner?(@user)
  end

  desc "Project has public builds enabled"
  condition(:public_builds, scope: :subject, score: 0) { project.public_builds? }

  # For guest access we use #team_member? so we can use
  # project.members, which gets cached in subject scope.
  # This is safe because team_access_level is guaranteed
  # by ProjectAuthorization's validation to be at minimum
  # GUEST
  desc "User has guest access"
  condition(:guest) { team_member? }

  desc "User has reporter access"
  condition(:reporter) { team_access_level >= Gitlab::Access::REPORTER }

  desc "User has developer access"
  condition(:developer) { team_access_level >= Gitlab::Access::DEVELOPER }

  desc "User has maintainer access"
  condition(:maintainer) { team_access_level >= Gitlab::Access::MAINTAINER }

  desc "User is a project bot"
  condition(:project_bot) { user.project_bot? && team_member? }

  desc "Project is public"
  condition(:public_project, scope: :subject, score: 0) { project.public? }

  desc "Project is visible to internal users"
  condition(:internal_access) do
    project.internal? && !user.external?
  end

  desc "User is a member of the group"
  condition(:group_member, scope: :subject) { project_group_member? }

  desc "Project is archived"
  condition(:archived, scope: :subject, score: 0) { project.archived? }

  condition(:default_issues_tracker, scope: :subject) { project.default_issues_tracker? }

  desc "Container registry is disabled"
  condition(:container_registry_disabled, scope: :subject) do
    !access_allowed_to?(:container_registry)
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

  desc "Deploy token with read_package_registry scope"
  condition(:read_package_registry_deploy_token) do
    user.is_a?(DeployToken) && user.has_access_to?(project) && user.read_package_registry
  end

  desc "Deploy token with write_package_registry scope"
  condition(:write_package_registry_deploy_token) do
    user.is_a?(DeployToken) && user.has_access_to?(project) && user.write_package_registry
  end

  desc "If user is authenticated via CI job token then the target project should be in scope"
  condition(:project_allowed_for_job_token) do
    !@user&.from_ci_job_token? || @user.ci_job_token_scope.includes?(project)
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
  condition(:service_desk_enabled) { @subject.service_desk_enabled? }

  with_scope :subject
  condition(:resource_access_token_feature_available) { resource_access_token_feature_available? }
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

  condition(:respect_protected_tag_for_release_permissions) do
    ::Feature.enabled?(:evalute_protected_tag_for_release_permissions, @subject, default_enabled: :yaml)
  end

  condition(:user_defined_variables_allowed) do
    !@subject.restrict_user_defined_variables?
  end

  with_scope :subject
  condition(:packages_disabled) { !@subject.packages_enabled }

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
    security_and_compliance
  ]

  features.each do |f|
    # these are scored high because they are unlikely
    desc "Project has #{f} disabled"
    condition(:"#{f}_disabled", score: 32) { !access_allowed_to?(f.to_sym) }
  end

  # `:read_project` may be prevented in EE, but `:read_project_for_iids` should
  # not.
  rule { guest | admin }.enable :read_project_for_iids

  rule { admin }.enable :update_max_artifacts_size
  rule { admin }.enable :read_storage_disk_path
  rule { can?(:read_all_resources) }.enable :read_confidential_issues

  rule { guest }.enable :guest_access
  rule { reporter }.enable :reporter_access
  rule { developer }.enable :developer_access
  rule { maintainer }.enable :maintainer_access
  rule { owner | admin }.enable :owner_access

  rule { can?(:owner_access) }.policy do
    enable :guest_access
    enable :reporter_access
    enable :developer_access
    enable :maintainer_access

    enable :change_namespace
    enable :change_visibility_level
    enable :rename_project
    enable :remove_project
    enable :archive_project
    enable :remove_fork_project
    enable :destroy_merge_request
    enable :destroy_issue

    enable :set_issue_iid
    enable :set_issue_created_at
    enable :set_issue_updated_at
    enable :set_note_created_at
    enable :set_emails_disabled
    enable :set_show_default_award_emojis
  end

  rule { can?(:guest_access) }.policy do
    enable :read_project
    enable :create_merge_request_in
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
  end

  rule { can?(:guest_access) & can?(:create_issue) }.enable :create_incident

  # These abilities are not allowed to admins that are not members of the project,
  # that's why they are defined separately.
  rule { guest & can?(:download_code) }.enable :build_download_code
  rule { guest & can?(:read_container_image) }.enable :build_read_container_image

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
    enable :admin_label
    enable :admin_issue_board_list
    enable :admin_issue_link
    enable :read_commit_status
    enable :read_build
    enable :read_container_image
    enable :read_deploy_board
    enable :read_pipeline
    enable :read_pipeline_schedule
    enable :read_environment
    enable :read_deployment
    enable :read_merge_request
    enable :read_sentry_issue
    enable :update_sentry_issue
    enable :read_prometheus
    enable :read_metrics_dashboard_annotation
    enable :metrics_dashboard
    enable :read_confidential_issues
    enable :read_package
    enable :read_product_analytics
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

  rule { operations_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:feature_flag))
    prevent(*create_read_update_admin_destroy(:environment))
    prevent(*create_read_update_admin_destroy(:sentry_issue))
    prevent(*create_read_update_admin_destroy(:alert_management_alert))
    prevent(*create_read_update_admin_destroy(:cluster))
    prevent(*create_read_update_admin_destroy(:terraform_state))
    prevent(*create_read_update_admin_destroy(:deployment))
    prevent(:metrics_dashboard)
    prevent(:read_pod_logs)
    prevent(:read_prometheus)
  end

  rule { can?(:metrics_dashboard) }.policy do
    enable :read_prometheus
    enable :read_deployment
  end

  rule { ~anonymous & can?(:metrics_dashboard) }.policy do
    enable :create_metrics_user_starred_dashboard
    enable :read_metrics_user_starred_dashboard
  end

  rule { packages_disabled | repository_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:package))
  end

  rule { owner | admin | guest | group_member }.prevent :request_access
  rule { ~request_access_enabled }.prevent :request_access

  rule { can?(:developer_access) & can?(:create_issue) }.enable :import_issues

  rule { can?(:developer_access) }.policy do
    enable :create_package
    enable :admin_issue_board
    enable :admin_merge_request
    enable :admin_milestone
    enable :update_merge_request
    enable :reopen_merge_request
    enable :create_commit_status
    enable :update_commit_status
    enable :create_build
    enable :update_build
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
    enable :create_release
    enable :update_release
    enable :create_metrics_dashboard_annotation
    enable :delete_metrics_dashboard_annotation
    enable :update_metrics_dashboard_annotation
    enable :read_alert_management_alert
    enable :update_alert_management_alert
    enable :create_design
    enable :move_design
    enable :destroy_design
    enable :read_terraform_state
    enable :read_pod_logs
    enable :read_feature_flag
    enable :create_feature_flag
    enable :update_feature_flag
    enable :destroy_feature_flag
    enable :admin_feature_flag
    enable :admin_feature_flags_user_lists
  end

  rule { can?(:developer_access) & user_confirmed? }.policy do
    enable :create_pipeline
    enable :update_pipeline
    enable :create_pipeline_schedule
  end

  rule { can?(:maintainer_access) }.policy do
    enable :destroy_package
    enable :admin_issue_board
    enable :push_to_delete_protected_branch
    enable :update_snippet
    enable :admin_snippet
    enable :admin_project_member
    enable :admin_note
    enable :admin_wiki
    enable :admin_project
    enable :admin_commit_status
    enable :admin_build
    enable :admin_container_image
    enable :admin_pipeline
    enable :admin_environment
    enable :admin_deployment
    enable :admin_pages
    enable :read_pages
    enable :update_pages
    enable :remove_pages
    enable :read_cluster
    enable :add_cluster
    enable :create_cluster
    enable :update_cluster
    enable :admin_cluster
    enable :create_environment_terminal
    enable :destroy_release
    enable :destroy_artifacts
    enable :admin_operations
    enable :read_deploy_token
    enable :create_deploy_token
    enable :destroy_deploy_token
    enable :read_prometheus_alerts
    enable :admin_terraform_state
    enable :create_freeze_period
    enable :read_freeze_period
    enable :update_freeze_period
    enable :destroy_freeze_period
    enable :admin_feature_flags_client
    enable :update_runners_registration_token
  end

  rule { public_project & metrics_dashboard_allowed }.policy do
    enable :metrics_dashboard
  end

  rule { internal_access & metrics_dashboard_allowed }.policy do
    enable :metrics_dashboard
  end

  rule { (mirror_available & can?(:admin_project)) | admin }.enable :admin_remote_mirror
  rule { can?(:push_code) }.enable :admin_tag

  rule { archived }.policy do
    prevent(*readonly_abilities)

    readonly_features.each do |feature|
      prevent(*create_update_admin_destroy(feature))
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

  rule { pages_disabled }.prevent :read_pages_content

  rule { issues_disabled & merge_requests_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:label))
    prevent(*create_read_update_admin_destroy(:milestone))
  end

  rule { snippets_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:snippet))
  end

  rule { analytics_disabled }.policy do
    prevent(:read_analytics)
    prevent(:read_insights)
    prevent(:read_cycle_analytics)
    prevent(:read_repository_graphs)
  end

  rule { wiki_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:wiki))
    prevent(:download_wiki_code)
  end

  rule { builds_disabled | repository_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:build))
    prevent(*create_read_update_admin_destroy(:pipeline_schedule))
    prevent(*create_read_update_admin_destroy(:environment))
    prevent(*create_read_update_admin_destroy(:cluster))
    prevent(*create_read_update_admin_destroy(:deployment))
  end

  # There's two separate cases when builds_disabled is true:
  # 1. When internal CI is disabled - builds_disabled && internal_builds_disabled
  #   - We do not prevent the user from accessing Pipelines to allow them to access external CI
  # 2. When the user is not allowed to access CI - builds_disabled && ~internal_builds_disabled
  #   - We prevent the user from accessing Pipelines
  rule { (builds_disabled & ~internal_builds_disabled) | repository_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:pipeline))
    prevent(*create_read_update_admin_destroy(:commit_status))
  end

  rule { repository_disabled }.policy do
    prevent :push_code
    prevent :download_code
    prevent :build_download_code
    prevent :fork_project
    prevent :read_commit_status
    prevent :read_pipeline
    prevent :read_pipeline_schedule
    prevent(*create_read_update_admin_destroy(:release))
    prevent(*create_read_update_admin_destroy(:feature_flag))
    prevent(:admin_feature_flags_user_lists)
  end

  rule { container_registry_disabled }.policy do
    prevent(*create_read_update_admin_destroy(:container_image))
  end

  rule { anonymous & ~public_project }.prevent_all

  rule { public_project }.policy do
    enable :public_access
    enable :read_project_for_iids
  end

  rule { ~project_allowed_for_job_token }.prevent_all

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
    enable :read_pipeline_schedule
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

    # NOTE: may be overridden by IssuePolicy
    enable :read_issue
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
  end

  rule { can?(:developer_access) }.policy do
    enable :read_security_configuration
  end

  # Design abilities could also be prevented in the issue policy.
  rule { design_management_disabled }.policy do
    prevent :read_design
    prevent :read_design_activity
    prevent :create_design
    prevent :destroy_design
    prevent :move_design
  end

  rule { download_code_deploy_key }.policy do
    enable :download_code
  end

  rule { push_code_deploy_key }.policy do
    enable :push_code
  end

  rule { read_package_registry_deploy_token }.policy do
    enable :read_package
    enable :read_project
  end

  rule { write_package_registry_deploy_token }.policy do
    enable :create_package
    enable :read_package
    enable :read_project
  end

  rule { can?(:create_pipeline) & can?(:maintainer_access) }.enable :create_web_ide_terminal

  rule { build_service_proxy_enabled }.enable :build_service_proxy_enabled

  rule { respect_protected_tag_for_release_permissions & can?(:developer_access) }.policy do
    enable :destroy_release
  end

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
  end

  rule { project_bot }.enable :project_bot_access

  rule { can?(:admin_project) & resource_access_token_feature_available }.policy do
    enable :read_resource_access_tokens
    enable :destroy_resource_access_tokens
  end

  rule { can?(:read_resource_access_tokens) & resource_access_token_creation_allowed }.policy do
    enable :create_resource_access_tokens
  end

  rule { can?(:project_bot_access) }.policy do
    prevent :create_resource_access_tokens
  end

  rule { user_defined_variables_allowed | can?(:maintainer_access) }.policy do
    enable :set_pipeline_variables
  end

  rule { ~security_and_compliance_disabled & can?(:developer_access) }.policy do
    enable :access_security_and_compliance
  end

  private

  def user_is_user?
    user.is_a?(User)
  end

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

  # rubocop: disable CodeReuse/ActiveRecord
  def project_group_member?
    return false if @user.nil?
    return false unless user_is_user?

    project.group &&
      (
        project.group.members_with_parents.exists?(user_id: @user.id) ||
        project.group.requesters.exists?(user_id: @user.id)
      )
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def team_access_level
    return -1 if @user.nil?
    return -1 unless user_is_user?

    lookup_access_level!
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
      can?(:read_all_resources) || team_access_level >= ProjectFeature.required_minimum_access_level(feature)
    else
      true
    end
  end

  def resource_access_token_feature_available?
    true
  end

  def resource_access_token_creation_allowed?
    group = project.group

    return true unless group # always enable for projects in personal namespaces

    resource_access_token_feature_available? && group.root_ancestor.namespace_settings.resource_access_token_creation_allowed?
  end

  def project
    @subject
  end
end

ProjectPolicy.prepend_mod_with('ProjectPolicy')
