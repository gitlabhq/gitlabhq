# frozen_string_literal: true

class GroupPolicy < Namespaces::GroupProjectNamespaceSharedPolicy
  include FindGroupProjects

  desc "Group is public"
  with_options scope: :subject, score: 0
  condition(:public_group) { @subject.public? }

  with_score 0
  condition(:logged_in_viewable) { @user && @subject.internal? && !@user.external? }

  condition(:has_access) { access_level != GroupMember::NO_ACCESS }

  condition(:guest) { access_level >= GroupMember::GUEST }
  # This is not a linear condition (some policies available for planner might not be available for higher access levels)
  condition(:planner) { access_level == GroupMember::PLANNER }
  condition(:developer) { access_level >= GroupMember::DEVELOPER }
  condition(:owner) { access_level >= GroupMember::OWNER }
  condition(:maintainer) { access_level >= GroupMember::MAINTAINER }
  condition(:reporter) { access_level >= GroupMember::REPORTER }

  condition(:has_parent, scope: :subject) { @subject.has_parent? }
  condition(:share_with_group_locked, scope: :subject) { @subject.share_with_group_lock? }
  condition(:parent_share_with_group_locked, scope: :subject) { @subject.parent&.share_with_group_lock? }
  condition(:can_change_parent_share_with_group_lock) { can?(:change_share_with_group_lock, @subject.parent) }
  condition(:migration_bot, scope: :user) { @user&.migration_bot? }
  condition(:can_read_group_member) { can_read_group_member? }

  desc "User is a project bot"
  condition(:project_bot) { user.project_bot? && access_level >= GroupMember::GUEST }

  condition(:has_projects) do
    group_projects_for(user: @user, group: @subject).any?
  end

  desc "User owns the group's organization"
  condition(:organization_owner) { owns_organization?(@subject.organization) }

  rule { admin | organization_owner }.enable :admin_organization

  with_options scope: :subject, score: 0
  condition(:request_access_enabled) { @subject.request_access_enabled }

  condition(:create_projects_disabled) do
    next true if @user.nil?

    visibility_levels = if can?(:admin_all_resources)
                          # admin can create projects even with restricted visibility levels
                          Gitlab::VisibilityLevel.values
                        else
                          Gitlab::VisibilityLevel.allowed_levels
                        end

    allowed_visibility_levels = visibility_levels.select do |level|
      Project.new(namespace: @subject).visibility_level_allowed?(level)
    end

    Group.prevent_project_creation?(user, @subject.project_creation_level) || allowed_visibility_levels.empty?
  end

  condition(:create_subgroup_disabled) do
    Gitlab::VisibilityLevel.allowed_levels_for_user(@user, @subject).empty?
  end

  condition(:owner_project_creation_level, scope: :subject) do
    @subject.project_creation_level == ::Gitlab::Access::OWNER_PROJECT_ACCESS
  end

  condition(:maintainer_project_creation_level, scope: :subject) do
    @subject.project_creation_level == ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS
  end

  condition(:developer_project_creation_level, scope: :subject) do
    @subject.project_creation_level == ::Gitlab::Access::DEVELOPER_PROJECT_ACCESS
  end

  condition(:maintainer_can_create_group, scope: :subject) do
    @subject.subgroup_creation_level == ::Gitlab::Access::MAINTAINER_SUBGROUP_ACCESS
  end

  condition(:design_management_enabled) do
    group_projects_for(user: @user, group: @subject, exclude_shared: false).any? { |p| p.design_management_enabled? }
  end

  condition(:dependency_proxy_available, scope: :subject) do
    @subject.dependency_proxy_feature_available?
  end

  condition(:dependency_proxy_access_allowed) do
    access_level(for_any_session: true) >= GroupMember::GUEST
  end

  desc "Deploy token with read_package_registry scope"
  condition(:read_package_registry_deploy_token) do
    @user.is_a?(DeployToken) && @user.groups.include?(@subject) && @user.read_package_registry
  end

  desc "Deploy token with write_package_registry scope"
  condition(:write_package_registry_deploy_token) do
    @user.is_a?(DeployToken) && @user.groups.include?(@subject) && @user.write_package_registry
  end

  with_scope :subject
  condition(:resource_access_token_feature_available) { resource_access_token_feature_available? }
  condition(:resource_access_token_creation_allowed) { resource_access_token_creation_allowed? }
  condition(:resource_access_token_create_feature_available) { resource_access_token_create_feature_available? }

  with_scope :subject
  condition(:has_project_with_service_desk_enabled) { @subject.has_project_with_service_desk_enabled? }

  with_scope :subject
  condition(:crm_enabled, score: 0, scope: :subject) { @subject.crm_enabled? }

  condition(:achievements_enabled, scope: :subject) do
    Feature.enabled?(:achievements, @subject)
  end

  condition(:group_runner_registration_allowed, scope: :subject) do
    @subject.runner_registration_enabled?
  end

  condition(:runner_registration_token_enabled, scope: :subject) do
    @subject.allow_runner_registration_token?
  end

  condition(:allow_guest_plus_roles_to_pull_packages_enabled, scope: :subject) do
    Feature.enabled?(:allow_guest_plus_roles_to_pull_packages, @subject.root_ancestor)
  end

  condition(:archived, scope: :subject) { @subject.self_or_ancestors_archived? }
  condition(:group_scheduled_for_deletion, scope: :subject) { @subject.scheduled_for_deletion_in_hierarchy_chain? }

  rule { archived }.policy do
    prevent :activate_group_member
    prevent :add_cluster
    prevent :admin_achievement
    prevent :admin_build
    prevent :admin_cluster
    prevent :admin_group_member
    prevent :admin_issue
    prevent :admin_issue_board
    prevent :admin_issue_board_list
    prevent :admin_label
    prevent :admin_member_access_request
    prevent :admin_milestone
    prevent :admin_note
    prevent :admin_package
    prevent :admin_pipeline
    prevent :admin_push_rules
    prevent :admin_runners
    prevent :admin_work_item
    prevent :award_achievement
    prevent :award_emoji
    prevent :change_group
    prevent :change_new_user_signups_cap
    prevent :change_prevent_sharing_groups_outside_hierarchy
    prevent :change_seat_control
    prevent :change_share_with_group_lock
    prevent :change_visibility_level
    prevent :create_cluster
    prevent :create_custom_emoji
    prevent :create_deploy_token
    prevent :create_jira_connect_subscription
    prevent :create_note
    prevent :create_observability_access_request
    prevent :create_package
    prevent :create_projects
    prevent :create_resource_access_tokens
    prevent :create_runners
    prevent :create_subgroup
    prevent :import_projects
    prevent :invite_group_members
    prevent :register_group_runners
    prevent :reopen_issue
    prevent :request_access
    prevent :resolve_note
    prevent :set_new_issue_metadata
    prevent :set_new_work_item_metadata
    prevent :set_show_diff_preview_in_email
    prevent :transfer_projects
    prevent :update_cluster
    prevent :update_default_branch_protection
    prevent :update_git_access_protocol
    prevent :update_issue
    prevent :update_max_artifacts_size
    prevent :update_o11y_settings
    prevent :update_runners_registration_token
    prevent :upload_file
    prevent :admin_tag
    prevent :push_code
    prevent :push_to_delete_protected_branch
    prevent :request_access
    prevent :upload_file
    prevent :resolve_note
    prevent :create_merge_request_from
    prevent :create_merge_request_in
    prevent :award_emoji
    prevent :create_incident
    prevent :admin_software_license_policy
    prevent :create_test_case
    prevent :admin_ai_catalog_item
    prevent :set_issue_created_at
    prevent :set_issue_updated_at
    prevent :set_epic_created_at
    prevent :set_epic_updated_at
    prevent :set_note_created_at
    prevent :admin_namespace
    prevent :change_visibility_level
    prevent :admin_integrations
    prevent :admin_cicd_variables
    prevent :admin_protected_environments
    prevent :manage_merge_request_settings
    prevent :create_deploy_token
    prevent :destroy_deploy_token
    prevent :register_group_runners
    prevent :update_runners_registration_token
    prevent :admin_runners
    prevent :admin_package
    prevent :admin_push_rules
    prevent :admin_cluster
    prevent :add_cluster
    prevent :create_cluster
    prevent :update_cluster
    prevent :create_jira_connect_subscription
    prevent :create_epic
    prevent :update_epic
    prevent :admin_epic
    prevent :destroy_epic
    prevent :create_iteration
    prevent :admin_iteration
    prevent :create_iteration_cadence
    prevent :admin_iteration_cadence
    prevent :rollover_issues
    prevent :admin_custom_field
    prevent :create_wiki
    prevent :admin_wiki
    prevent :admin_merge_request
    prevent :admin_vulnerability
    prevent :modify_security_policy
    prevent :admin_compliance_framework
    prevent :admin_compliance_pipeline_configuration
  end

  rule { archived & ~group_scheduled_for_deletion }.policy do
    prevent :delete_custom_emoji
    prevent :delete_o11y_settings
    prevent :destroy_issue
    prevent :destroy_package
    prevent :destroy_upload
    prevent :destroy_user_achievement
  end

  rule { can?(:read_group) & design_management_enabled }.policy do
    enable :read_design_activity
  end

  rule { public_group }.policy do
    enable :read_group
    enable :read_package
  end

  rule { logged_in_viewable }.enable :read_group

  rule { guest }.policy do
    enable :read_group
    enable :guest_access
    enable :read_release
    enable :award_emoji
  end

  rule { guest | can?(:admin_issue) }.policy do
    enable :set_new_issue_metadata
    enable :set_new_work_item_metadata
  end

  rule { planner }.policy do
    enable :planner_access
    enable :guest_access
    enable :admin_label
    enable :admin_milestone
    enable :admin_issue_board
    enable :admin_issue_board_list
    enable :admin_issue
    enable :admin_work_item
    enable :update_issue
    enable :read_confidential_issues
    enable :read_crm_organization
    enable :read_crm_contact
    enable :read_internal_note
  end

  rule { admin | organization_owner }.policy do
    enable :read_group
  end

  rule { admin }.policy do
    enable :update_max_artifacts_size
    enable :create_projects
  end

  rule { can?(:read_all_resources) }.policy do
    enable :read_confidential_issues
  end

  rule { has_projects }.policy do
    enable :read_group
  end

  rule { can?(:read_group) }.policy do
    enable :read_milestone
    enable :read_issue_board_list
    enable :read_label
    enable :read_issue_board
    enable :read_group_member
    enable :read_custom_emoji
    enable :read_counts
    enable :read_issue
    enable :read_work_item
    enable :read_namespace
    enable :read_upload
    enable :read_group_metadata
    enable :upload_file
  end

  rule { anonymous }.prevent :upload_file

  rule { ~achievements_enabled }.policy do
    prevent :read_achievement
    prevent :admin_achievement
    prevent :award_achievement
    prevent :destroy_user_achievement
  end

  rule { can?(:read_group) }.policy do
    enable :read_achievement
  end

  rule { can?(:owner_access) }.policy do
    enable :destroy_user_achievement
    enable :set_issue_created_at
    enable :set_issue_updated_at
  end

  rule { ~public_group & ~has_access }.prevent :read_counts

  rule { ~can_read_group_member }.policy do
    prevent :read_group_member
  end

  rule { ~can?(:read_group) }.policy do
    prevent :read_design_activity
  end

  rule { has_access }.enable :read_namespace_via_membership

  rule { developer }.policy do
    enable :create_custom_emoji
    enable :create_observability_access_request
    enable :update_o11y_settings
    enable :delete_o11y_settings
    enable :create_package
    enable :developer_access
    enable :admin_crm_organization
    enable :admin_crm_contact
    enable :read_cluster # Deprecated as certificate-based cluster integration (`Clusters::Cluster`).
    enable :read_cluster_agent
    enable :read_group_all_available_runners
    enable :read_observability_portal
  end

  rule { reporter }.policy do
    enable :reporter_access
    enable :read_container_image
    enable :read_harbor_registry
    enable :admin_issue_board
    enable :admin_label
    enable :admin_milestone
    enable :admin_issue_board_list
    enable :admin_issue
    enable :admin_work_item
    enable :update_issue
    enable :read_prometheus
    enable :read_package
    enable :read_crm_organization
    enable :read_crm_contact
    enable :read_confidential_issues
    enable :read_ci_cd_analytics
    enable :read_internal_note
  end

  rule { maintainer }.policy do
    enable :maintainer_access
    enable :add_cluster
    enable :admin_achievement
    enable :admin_build
    enable :admin_cluster
    enable :admin_pipeline
    enable :admin_push_rules
    enable :admin_upload
    enable :award_achievement
    enable :create_cluster
    enable :create_jira_connect_subscription
    enable :destroy_package
    enable :destroy_upload
    enable :import_projects
    enable :read_deploy_token
    enable :update_cluster

    # doc/ci/runners/runners_scope.md#group-runners
    # doc/user/permissions.md#cicd-group-permissions
    enable :read_runners
  end

  rule { owner }.policy do
    enable :owner_access
    enable :admin_cicd_variables
    enable :admin_group
    enable :admin_group_member
    enable :admin_integrations
    enable :admin_namespace
    enable :admin_package
    enable :admin_protected_environments
    enable :archive_group
    enable :change_group
    enable :change_new_user_signups_cap
    enable :change_prevent_sharing_groups_outside_hierarchy
    enable :change_seat_control
    enable :change_visibility_level
    enable :create_deploy_token
    enable :create_group_link
    enable :create_subgroup
    enable :delete_group_link
    enable :destroy_deploy_token
    enable :destroy_issue
    enable :edit_billing
    enable :manage_merge_request_settings
    enable :read_billing
    enable :read_usage_quotas
    enable :remove_group
    enable :set_emails_disabled
    enable :set_note_created_at
    enable :set_show_diff_preview_in_email
    enable :update_default_branch_protection
    enable :update_git_access_protocol

    # doc/ci/runners/runners_scope.md#group-runners
    # doc/user/permissions.md#cicd-group-permissions
    enable :admin_runners
    enable :create_runners
    enable :read_runners
    enable :read_runners_registration_token
    enable :register_group_runners
    enable :update_group_link
    enable :update_runners_registration_token
  end

  rule { can?(:read_nested_project_resources) }.policy do
    enable :read_group_activity
    enable :read_group_issues
    enable :read_group_boards
    enable :read_group_labels
    enable :read_group_milestones
    enable :read_group_merge_requests
    enable :read_group_build_report_results
  end

  rule { can?(:read_cross_project) & can?(:read_group) }.policy do
    enable :read_nested_project_resources
  end

  rule { maintainer & maintainer_can_create_group }.enable :create_subgroup

  rule { public_group | logged_in_viewable }.enable :view_globally

  rule { default }.enable(:request_access)

  rule { ~request_access_enabled }.prevent :request_access
  rule { ~can?(:view_globally) }.prevent   :request_access
  rule { has_access }.prevent              :request_access

  rule do
    owner & (~share_with_group_locked | ~has_parent | ~parent_share_with_group_locked | can_change_parent_share_with_group_lock)
  end.enable :change_share_with_group_lock

  rule { owner & owner_project_creation_level }.enable :create_projects
  rule { maintainer & maintainer_project_creation_level }.enable :create_projects
  rule { developer & developer_project_creation_level }.enable :create_projects
  rule { create_projects_disabled }.policy do
    prevent :create_projects
    prevent :import_projects
  end

  rule { create_subgroup_disabled }.policy do
    prevent :create_subgroup
  end

  rule { owner | admin | organization_owner }.policy do
    enable :owner_access
    enable :read_statistics
  end

  rule { maintainer & can?(:create_projects) }.policy do
    enable :transfer_projects
    enable :import_projects
  end

  rule { read_package_registry_deploy_token }.policy do
    enable :read_package
    enable :read_group
  end

  rule { write_package_registry_deploy_token }.policy do
    enable :create_package
    enable :read_package
    enable :read_group
  end

  rule { dependency_proxy_access_allowed & dependency_proxy_available }
    .enable :read_dependency_proxy

  rule { owner & dependency_proxy_available }.policy do
    enable :admin_dependency_proxy
  end

  rule { project_bot }.enable :project_bot_access

  rule { can?(:admin_group) & resource_access_token_feature_available }.policy do
    enable :read_resource_access_tokens
    enable :destroy_resource_access_tokens
  end

  rule { can?(:admin_group) & resource_access_token_create_feature_available }.policy do
    enable :admin_setting_to_allow_resource_access_token_creation
  end

  rule { resource_access_token_creation_allowed & can?(:read_resource_access_tokens) }.policy do
    enable :create_resource_access_tokens
    enable :manage_resource_access_tokens
  end

  rule { can?(:project_bot_access) }.policy do
    prevent :create_resource_access_tokens
    prevent :manage_resource_access_tokens
  end

  rule { can?(:admin_group_member) }.policy do
    # ability to read, approve or reject member access requests of other users
    enable :admin_member_access_request
    enable :read_member_access_request

    # ability to activate group members
    enable :activate_group_member
  end

  rule { support_bot & has_project_with_service_desk_enabled }.policy do
    enable :read_label
  end

  rule { ~crm_enabled }.policy do
    prevent :read_crm_contact
    prevent :read_crm_organization
    prevent :admin_crm_contact
    prevent :admin_crm_organization
  end

  rule { ~admin & ~group_runner_registration_allowed }.policy do
    prevent :register_group_runners
    prevent :create_runners
  end

  rule { ~runner_registration_token_enabled }.policy do
    prevent :register_group_runners
    prevent :read_runners_registration_token
    prevent :update_runners_registration_token
  end

  rule { migration_bot }.policy do
    enable :read_resource_access_tokens
    enable :destroy_resource_access_tokens
  end

  rule { can?(:admin_group) | can?(:admin_runners) }.enable :admin_group_or_admin_runners

  rule { can?(:remove_group) | can?(:archive_group) }.enable :view_edit_page

  # TODO: Remove this rule and move :read_package permission from reporter to guest
  # with the rollout of the FF allow_guest_plus_roles_to_pull_packages
  # https://gitlab.com/gitlab-org/gitlab/-/issues/512210
  rule { guest & allow_guest_plus_roles_to_pull_packages_enabled }.enable :read_package

  rule { can?(:admin_group_member) }.policy do
    enable :invite_group_members
  end

  def access_level(for_any_session: false)
    return GroupMember::NO_ACCESS if @user.nil?
    return GroupMember::NO_ACCESS unless user_is_user?

    @access_level ||= lookup_access_level!(for_any_session: for_any_session)
  end

  def lookup_access_level!(for_any_session: false)
    @subject.max_member_access_for_user(@user)
  end

  private

  def group
    @subject
  end

  def resource_access_token_feature_available?
    true
  end

  def resource_access_token_create_feature_available?
    true
  end

  def can_read_group_member?
    !(@subject.private? && access_level == GroupMember::NO_ACCESS)
  end

  def resource_access_token_creation_allowed?
    resource_access_token_create_feature_available? && group.root_ancestor.namespace_settings.resource_access_token_creation_allowed?
  end
end

GroupPolicy.prepend_mod_with('GroupPolicy')
