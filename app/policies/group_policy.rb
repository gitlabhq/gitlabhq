# frozen_string_literal: true

class GroupPolicy < BasePolicy
  include FindGroupProjects

  desc "Group is public"
  with_options scope: :subject, score: 0
  condition(:public_group) { @subject.public? }

  with_score 0
  condition(:logged_in_viewable) { @user && @subject.internal? && !@user.external? }

  condition(:has_access) { access_level != GroupMember::NO_ACCESS }

  condition(:guest) { access_level >= GroupMember::GUEST }
  condition(:developer) { access_level >= GroupMember::DEVELOPER }
  condition(:owner) { access_level >= GroupMember::OWNER }
  condition(:maintainer) { access_level >= GroupMember::MAINTAINER }
  condition(:reporter) { access_level >= GroupMember::REPORTER }

  condition(:has_parent, scope: :subject) { @subject.has_parent? }
  condition(:share_with_group_locked, scope: :subject) { @subject.share_with_group_lock? }
  condition(:parent_share_with_group_locked, scope: :subject) { @subject.parent&.share_with_group_lock? }
  condition(:can_change_parent_share_with_group_lock) { can?(:change_share_with_group_lock, @subject.parent) }

  condition(:has_projects) do
    group_projects_for(user: @user, group: @subject).any?
  end

  with_options scope: :subject, score: 0
  condition(:request_access_enabled) { @subject.request_access_enabled }

  condition(:create_projects_disabled) do
    @subject.project_creation_level == ::Gitlab::Access::NO_ONE_PROJECT_ACCESS
  end

  condition(:developer_maintainer_access) do
    @subject.project_creation_level == ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS
  end

  condition(:maintainer_can_create_group) do
    @subject.subgroup_creation_level == ::Gitlab::Access::MAINTAINER_SUBGROUP_ACCESS
  end

  condition(:design_management_enabled) do
    group_projects_for(user: @user, group: @subject, only_owned: false).any? { |p| p.design_management_enabled? }
  end

  condition(:dependency_proxy_available) do
    @subject.dependency_proxy_feature_available?
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

  with_scope :subject
  condition(:has_project_with_service_desk_enabled) { @subject.has_project_with_service_desk_enabled? }

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
    enable :upload_file
  end

  rule { admin }.policy do
    enable :read_group
    enable :update_max_artifacts_size
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
  end

  rule { ~can?(:read_group) }.policy do
    prevent :read_design_activity
  end

  rule { has_access }.enable :read_namespace

  rule { developer }.policy do
    enable :admin_milestone
    enable :create_metrics_dashboard_annotation
    enable :delete_metrics_dashboard_annotation
    enable :update_metrics_dashboard_annotation
    enable :create_custom_emoji
    enable :create_package_settings
  end

  rule { reporter }.policy do
    enable :reporter_access
    enable :read_container_image
    enable :admin_issue_board
    enable :admin_label
    enable :admin_issue_board_list
    enable :admin_issue
    enable :read_metrics_dashboard_annotation
    enable :read_prometheus
    enable :read_package
    enable :read_package_settings
  end

  rule { maintainer }.policy do
    enable :create_projects
    enable :admin_pipeline
    enable :admin_build
    enable :read_cluster
    enable :add_cluster
    enable :create_cluster
    enable :update_cluster
    enable :admin_cluster
    enable :read_deploy_token
    enable :create_jira_connect_subscription
    enable :update_runners_registration_token
  end

  rule { owner }.policy do
    enable :admin_group
    enable :admin_namespace
    enable :admin_group_member
    enable :change_visibility_level

    enable :set_note_created_at
    enable :set_emails_disabled
    enable :change_prevent_sharing_groups_outside_hierarchy
    enable :change_new_user_signups_cap
    enable :update_default_branch_protection
    enable :create_deploy_token
    enable :destroy_deploy_token
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

  rule { owner }.enable :create_subgroup
  rule { maintainer & maintainer_can_create_group }.enable :create_subgroup

  rule { public_group | logged_in_viewable }.enable :view_globally

  rule { default }.enable(:request_access)

  rule { ~request_access_enabled }.prevent :request_access
  rule { ~can?(:view_globally) }.prevent   :request_access
  rule { has_access }.prevent              :request_access

  rule { owner & (~share_with_group_locked | ~has_parent | ~parent_share_with_group_locked | can_change_parent_share_with_group_lock) }.enable :change_share_with_group_lock

  rule { developer & developer_maintainer_access }.enable :create_projects
  rule { create_projects_disabled }.prevent :create_projects

  rule { owner | admin }.policy do
    enable :owner_access
    enable :read_statistics
  end

  rule { maintainer & can?(:create_projects) }.enable :transfer_projects

  rule { read_package_registry_deploy_token }.policy do
    enable :read_package
    enable :read_group
  end

  rule { write_package_registry_deploy_token }.policy do
    enable :create_package
    enable :read_package
    enable :read_group
  end

  rule { can?(:read_group) & dependency_proxy_available }
    .enable :read_dependency_proxy

  rule { developer & dependency_proxy_available }
    .enable :admin_dependency_proxy

  rule { can?(:admin_group) & resource_access_token_feature_available }.policy do
    enable :read_resource_access_tokens
    enable :destroy_resource_access_tokens
    enable :admin_setting_to_allow_project_access_token_creation
  end

  rule { resource_access_token_creation_allowed & can?(:read_resource_access_tokens) }.policy do
    enable :create_resource_access_tokens
  end

  rule { support_bot & has_project_with_service_desk_enabled }.policy do
    enable :read_label
  end

  def access_level
    return GroupMember::NO_ACCESS if @user.nil?
    return GroupMember::NO_ACCESS unless user_is_user?

    @access_level ||= lookup_access_level!
  end

  def lookup_access_level!
    @subject.max_member_access_for_user(@user)
  end

  private

  def user_is_user?
    user.is_a?(User)
  end

  def group
    @subject
  end

  def resource_access_token_feature_available?
    true
  end

  def resource_access_token_creation_allowed?
    resource_access_token_feature_available? && group.root_ancestor.namespace_settings.resource_access_token_creation_allowed?
  end
end

GroupPolicy.prepend_mod_with('GroupPolicy')
