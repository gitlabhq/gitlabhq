class ProjectTeam
  attr_accessor :project

  def initialize(project)
    @project = project
  end

  # Shortcut to add users
  #
  # Use:
  #   @team << [@user, :master]
  #   @team << [@users, :master]
  #
  def <<(args)
    users, access, current_user = *args

    if users.respond_to?(:each)
      add_users(users, access, current_user)
    else
      add_user(users, access, current_user)
    end
  end

  def find_member(user_id)
    member = project.members.find_by(user_id: user_id)

    # If user is not in project members
    # we should check for group membership
    if group && !member
      member = group.members.find_by(user_id: user_id)
    end

    member
  end

  def add_users(users, access, current_user = nil)
    return false if group_member_lock

    ProjectMember.add_users_into_projects(
      [project.id],
      users,
      access,
      current_user
    )
  end

  def add_user(user, access, current_user = nil)
    add_users([user], access, current_user)
  end

  # Remove all users from project team
  def truncate
    ProjectMember.truncate_team(project)
  end

  def members
    @members ||= fetch_members
  end
  alias_method :users, :members

  def guests
    @guests ||= fetch_members(:guests)
  end

  def reporters
    @reporters ||= fetch_members(:reporters)
  end

  def developers
    @developers ||= fetch_members(:developers)
  end

  def masters
    @masters ||= fetch_members(:masters)
  end

  def import(source_project, current_user = nil)
    target_project = project

    source_members = source_project.project_members.to_a
    target_user_ids = target_project.project_members.pluck(:user_id)

    source_members.reject! do |member|
      # Skip if user already present in team
      !member.invite? && target_user_ids.include?(member.user_id)
    end

    source_members.map! do |member|
      new_member = member.dup
      new_member.id = nil
      new_member.source = target_project
      new_member.created_by = current_user
      new_member
    end

    ProjectMember.transaction do
      source_members.each do |member|
        member.save
      end
    end

    true
  rescue
    false
  end

  def guest?(user)
    max_member_access(user.id) == Gitlab::Access::GUEST
  end

  def reporter?(user)
    max_member_access(user.id) == Gitlab::Access::REPORTER
  end

  def developer?(user)
    max_member_access(user.id) == Gitlab::Access::DEVELOPER
  end

  def master?(user)
    max_member_access(user.id) == Gitlab::Access::MASTER
  end

  def member?(user, min_member_access = nil)
    member = !!find_member(user.id)

    if min_member_access
      member && max_member_access(user.id) >= min_member_access
    else
      member
    end
  end

  def human_max_access(user_id)
    Gitlab::Access.options_with_owner.key(max_member_access(user_id))
  end

  # This method assumes project and group members are eager loaded for optimal
  # performance.
  def max_member_access(user_id)
    access = []

    access += project.members.where(user_id: user_id).has_access.pluck(:access_level)

    if group
      access += group.members.where(user_id: user_id).has_access.pluck(:access_level)
    end

    if project.invited_groups.any? && project.allowed_to_share_with_group?
      access << max_invited_level(user_id)
    end

    access.compact.max
  end

  private

  def max_invited_level(user_id)
    project.project_group_links.map do |group_link|
      invited_group = group_link.group
      access = invited_group.group_members.find_by(user_id: user_id).try(:access_field)

      # If group member has higher access level we should restrict it
      # to max allowed access level
      if access && access > group_link.group_access
        access = group_link.group_access
      end

      access
    end.compact.max
  end

  def fetch_members(level = nil)
    project_members = project.members
    group_members = group ? group.members : []
    invited_members = []

    if project.invited_groups.any? && project.allowed_to_share_with_group?
      project.project_group_links.each do |group_link|
        invited_group = group_link.group
        im = invited_group.members

        if level
          int_level = GroupMember.access_level_roles[level.to_s.singularize.titleize]

          # Skip group members if we ask for masters
          # but max group access is developers
          next if int_level > group_link.group_access

          # If we ask for developers and max
          # group access is developers we need to provide
          # both group master, developers as devs
          if int_level == group_link.group_access
            im.where("access_level >= ?)", group_link.group_access)
          else
            im.send(level)
          end
        end

        invited_members << im
      end

      invited_members = invited_members.flatten.compact
    end

    if level
      project_members = project_members.send(level)
      group_members = group_members.send(level) if group
    end

    user_ids = project_members.pluck(:user_id)
    user_ids.push(*invited_members.map(&:user_id)) if invited_members.any?
    user_ids.push(*group_members.pluck(:user_id)) if group

    User.where(id: user_ids)
  end

  def group
    project.group
  end

  def group_member_lock
    group && group.membership_lock
  end
end
