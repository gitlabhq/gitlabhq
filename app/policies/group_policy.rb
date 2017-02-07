class GroupPolicy < BasePolicy
  def rules
    can! :read_group if @subject.public?
    return unless @user

    globally_viewable = @subject.public? || (@subject.internal? && !@user.external?)
    member = @subject.users_with_parents.include?(@user)
    owner = @user.admin? || @subject.has_owner?(@user)
    master = owner || @subject.has_master?(@user)

    can_read = false
    can_read ||= globally_viewable
    can_read ||= member
    can_read ||= @user.admin?
    can_read ||= @user.auditor?
    can_read ||= GroupProjectsFinder.new(@subject).execute(@user).any?
    can! :read_group if can_read

    # Only group masters and group owners can create new projects
    if master
      can! :create_projects
      can! :admin_milestones
      can! :admin_label
    end

    # Only group owner and administrators can admin group
    if owner
      can! :admin_group
      can! :admin_namespace
      can! :admin_group_member
      can! :change_visibility_level
    end

    if globally_viewable && @subject.request_access_enabled && !member
      can! :request_access
    end

    additional_rules!(master)
  end

  def can_read_group?
    return true if @subject.public?
    return true if @user.admin?
    return true if @user.auditor?
    return true if @subject.internal? && !@user.external?
    return true if @subject.users.include?(@user)

    GroupProjectsFinder.new(@subject).execute(@user).any?
  end

  def additional_rules!(master)
    if @subject.ldap_synced?
      cannot! :admin_group_member
      can! :override_group_member if master
    end
  end
end
