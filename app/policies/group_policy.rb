class GroupPolicy < BasePolicy
  prepend EE::GroupPolicy

  desc "Group is public"
  with_options scope: :subject, score: 0
  condition(:public_group) { @subject.public? }

  with_score 0
  condition(:logged_in_viewable) { @user && @subject.internal? && !@user.external? }

  condition(:has_access) { access_level != GroupMember::NO_ACCESS }

  condition(:guest) { access_level >= GroupMember::GUEST }
  condition(:owner) { access_level >= GroupMember::OWNER }
  condition(:master) { access_level >= GroupMember::MASTER }
  condition(:reporter) { access_level >= GroupMember::REPORTER }

  condition(:has_projects) do
    GroupProjectsFinder.new(group: @subject, current_user: @user).execute.any?
  end

  with_options scope: :subject, score: 0
  condition(:request_access_enabled) { @subject.request_access_enabled }

  rule { public_group }      .enable :read_group
  rule { logged_in_viewable }.enable :read_group
  rule { guest }             .enable :read_group
  rule { admin }             .enable :read_group
  rule { has_projects }      .enable :read_group

  rule { reporter }.enable :admin_label

  rule { master }.policy do
    enable :create_projects
    enable :admin_milestones
    enable :admin_pipeline
    enable :admin_build
  end

  rule { owner }.policy do
    enable :admin_group
    enable :admin_namespace
    enable :admin_group_member
    enable :change_visibility_level
  end

  rule { owner & can_create_group }.enable :create_subgroup

  rule { public_group | logged_in_viewable }.enable :view_globally

  rule { default }.enable(:request_access)

  rule { ~request_access_enabled }.prevent :request_access
  rule { ~can?(:view_globally) }.prevent   :request_access
  rule { has_access }.prevent              :request_access

  def access_level
    return GroupMember::NO_ACCESS if @user.nil?

    @access_level ||= @subject.max_member_access_for_user(@user)
  end
end
