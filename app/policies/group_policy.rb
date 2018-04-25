class GroupPolicy < BasePolicy
  desc "Group is public"
  with_options scope: :subject, score: 0
  condition(:public_group) { @subject.public? }

  with_score 0
  condition(:logged_in_viewable) { @user && @subject.internal? && !@user.external? }

  condition(:has_access) { access_level != GroupMember::NO_ACCESS }

  condition(:guest) { access_level >= GroupMember::GUEST }
  condition(:developer) { access_level >= GroupMember::DEVELOPER }
  condition(:owner) { access_level >= GroupMember::OWNER }
  condition(:master) { access_level >= GroupMember::MASTER }
  condition(:reporter) { access_level >= GroupMember::REPORTER }

  condition(:nested_groups_supported, scope: :global) { Group.supports_nested_groups? }

  condition(:has_parent, scope: :subject) { @subject.has_parent? }
  condition(:share_with_group_locked, scope: :subject) { @subject.share_with_group_lock? }
  condition(:parent_share_with_group_locked, scope: :subject) { @subject.parent&.share_with_group_lock? }
  condition(:can_change_parent_share_with_group_lock) { can?(:change_share_with_group_lock, @subject.parent) }

  condition(:has_projects) do
    GroupProjectsFinder.new(group: @subject, current_user: @user, options: { include_subgroups: true }).execute.any?
  end

  with_options scope: :subject, score: 0
  condition(:request_access_enabled) { @subject.request_access_enabled }

  rule { public_group }.policy do
    enable :read_group
    enable :read_list
    enable :read_label
  end

  rule { logged_in_viewable }.enable :read_group

  rule { guest }.policy do
    enable :read_group
    enable :upload_file
    enable :read_label
  end

  rule { admin }             .enable :read_group

  rule { has_projects }.policy do
    enable :read_group
    enable :read_label
  end

  rule { has_access }.enable :read_namespace

  rule { developer }.enable :admin_milestones

  rule { reporter }.policy do
    enable :admin_label
    enable :admin_list
    enable :admin_issue
  end

  rule { master }.policy do
    enable :create_projects
    enable :admin_pipeline
    enable :admin_build
  end

  rule { owner }.policy do
    enable :admin_group
    enable :admin_namespace
    enable :admin_group_member
    enable :change_visibility_level
  end

  rule { owner & nested_groups_supported }.enable :create_subgroup

  rule { public_group | logged_in_viewable }.enable :view_globally

  rule { default }.enable(:request_access)

  rule { ~request_access_enabled }.prevent :request_access
  rule { ~can?(:view_globally) }.prevent   :request_access
  rule { has_access }.prevent              :request_access

  rule { owner & (~share_with_group_locked | ~has_parent | ~parent_share_with_group_locked | can_change_parent_share_with_group_lock) }.enable :change_share_with_group_lock

  def access_level
    return GroupMember::NO_ACCESS if @user.nil?

    @access_level ||= @subject.max_member_access_for_user(@user)
  end
end
