# frozen_string_literal: true

class GroupPolicy < Namespaces::GroupProjectNamespaceSharedPolicy
  include FindGroupProjects
  include ::Authz::RolePermissions
  include ::Authn::SubgroupProvisionedServiceAccountRestriction

  define_role_permissions(:group)

  desc "Group is public"
  with_options scope: :subject, score: 0
  condition(:public_group) { @subject.public? }

  with_score 0
  condition(:logged_in_viewable) { @user && @subject.try(:internal?) && !@user.external? }

  condition(:has_access) { access_level != GroupMember::NO_ACCESS }

  condition(:guest) { access_level >= GroupMember::GUEST }
  # Planner is a non-hierarchical role (some permissions available for planner might not be available for higher access levels)
  condition(:planner) { access_level == GroupMember::PLANNER }
  condition(:reporter) { access_level >= GroupMember::REPORTER }
  # Security manager is a non-hierarchical role (some permissions available for security_manager might not be available for higher access levels)
  condition(:security_manager) { Gitlab::Security::SecurityManagerConfig.enabled? && access_level == GroupMember::SECURITY_MANAGER }
  condition(:developer) { access_level >= GroupMember::DEVELOPER }
  condition(:maintainer) { access_level >= GroupMember::MAINTAINER }
  condition(:owner) { access_level >= GroupMember::OWNER }

  condition(:has_parent, scope: :subject) { @subject.has_parent? }
  condition(:is_root_namespace, scope: :subject) { @subject.root? }
  condition(:share_with_group_locked, scope: :subject) { @subject.share_with_group_lock? }
  condition(:parent_share_with_group_locked, scope: :subject) { @subject.parent&.share_with_group_lock? }
  condition(:can_change_parent_share_with_group_lock) { can?(:change_share_with_group_lock, @subject.parent) }
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
      Project.new(group: @subject).visibility_level_allowed?(level)
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

  condition(:ai_service_account_with_composite_identity) do
    next false unless @user&.ai_service_account?

    identity = ::Gitlab::Auth::Identity.fabricate(@user)
    identity&.linked?
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
    prevent(*Authz::PermissionGroups::Internal.get('group:archived').permissions)
  end

  rule { public_group }.policy do
    enable(*Authz::Role.get(:public_anonymous).direct_permissions(:group))
  end

  rule { admin }.policy do
    enable(*Authz::Role.get(:admin).permissions(:group))
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

  rule { logged_in_viewable }.enable :read_group

  rule { admin | organization_owner }.policy do
    enable :read_group
  end

  rule { has_projects }.policy do
    enable(*Authz::Role.get(:descendant_project_member).direct_permissions(:group))
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
    enable :read_work_item_type
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

  rule { ~public_group & ~has_access }.prevent :read_counts

  rule { ~can_read_group_member }.policy do
    prevent :read_group_member
  end

  rule { ~can?(:read_group) }.policy do
    prevent :read_design_activity
  end

  rule { has_access }.enable :read_namespace_via_membership

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
    enable :read_statistics
    enable :update_group_organization
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

  # AI service accounts (service_account? && composite_identity_enforced?) are not group members,
  # so they fail the normal dependency_proxy_access_allowed membership check. Instead, we grant
  # them access via ai_service_account_with_composite_identity, which verifies the composite
  # identity is linked. The scoped user's own group access is then enforced by the dual-check
  # in Ability#with_composite_identity_check - both the AI service account and the scoped user
  # must independently satisfy the ability for access to be granted.
  rule { (dependency_proxy_access_allowed | ai_service_account_with_composite_identity) & dependency_proxy_available }
    .enable :read_dependency_proxy

  rule { ~dependency_proxy_available }.prevent :admin_dependency_proxy

  rule { project_bot }.enable :project_bot_access

  rule { ~resource_access_token_feature_available }.policy do
    prevent :read_resource_access_tokens
    prevent :destroy_resource_access_tokens
  end

  rule { ~resource_access_token_create_feature_available }.policy do
    prevent :admin_setting_to_allow_resource_access_token_creation
  end

  rule { resource_access_token_creation_allowed & can?(:read_resource_access_tokens) }.policy do
    enable :create_resource_access_tokens
    enable :manage_resource_access_tokens
  end

  rule { can?(:project_bot_access) }.policy do
    prevent :create_resource_access_tokens
    prevent :manage_resource_access_tokens
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

  rule { can?(:admin_runners) }.enable :admin_group_or_admin_runners

  rule { can?(:remove_group) | can?(:archive_group) }.enable :view_edit_page

  # TODO: Remove this rule and move :read_package permission from reporter to guest
  # with the rollout of the FF allow_guest_plus_roles_to_pull_packages
  # https://gitlab.com/gitlab-org/gitlab/-/issues/512210
  rule { guest & allow_guest_plus_roles_to_pull_packages_enabled }.enable :read_package

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
