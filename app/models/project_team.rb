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
    return false if group_member_lock
    users = args.first

    if users.respond_to?(:each)
      add_users(users, args.second)
    else
      add_user(users, args.second)
    end
  end

  def find(user_id)
    user = project.users.find_by(id: user_id)

    if group
      user ||= group.users.find_by(id: user_id)
    end

    user
  end

  def find_tm(user_id)
    tm = project.project_members.find_by(user_id: user_id)

    # If user is not in project members
    # we should check for group membership
    if group && !tm
      tm = group.group_members.find_by(user_id: user_id)
    end

    tm
  end

  def add_user(user, access)
    add_users_ids([user.id], access)
  end

  def add_users(users, access)
    add_users_ids(users.map(&:id), access)
  end

  def add_users_ids(user_ids, access)
    ProjectMember.add_users_into_projects(
      [project.id],
      user_ids,
      access
    )
  end

  # Remove all users from project team
  def truncate
    ProjectMember.truncate_team(project)
  end

  def users
    members
  end

  def members
    @members ||= fetch_members
  end

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

  def import(source_project)
    target_project = project

    source_team = source_project.project_members.to_a
    target_user_ids = target_project.project_members.pluck(:user_id)

    source_team.reject! do |tm|
      # Skip if user already present in team
      target_user_ids.include?(tm.user_id)
    end

    source_team.map! do |tm|
      new_tm = tm.dup
      new_tm.id = nil
      new_tm.source = target_project
      new_tm
    end

    ProjectMember.transaction do
      source_team.each do |tm|
        tm.save
      end
    end

    true
  rescue
    false
  end

  def guest?(user)
    max_tm_access(user.id) == Gitlab::Access::GUEST
  end

  def reporter?(user)
    max_tm_access(user.id) == Gitlab::Access::REPORTER
  end

  def developer?(user)
    max_tm_access(user.id) == Gitlab::Access::DEVELOPER
  end

  def master?(user)
    max_tm_access(user.id) == Gitlab::Access::MASTER
  end

  def member?(user_id)
    !!find_tm(user_id)
  end

  def max_tm_access(user_id)
    access = []
    access << project.project_members.find_by(user_id: user_id).try(:access_field)

    if group
      access << group.group_members.find_by(user_id: user_id).try(:access_field)
    end

    if project.invited_groups.any?
      access << max_invited_level(user_id)
    end

    access.compact.max
  end


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

  private

  def fetch_members(level = nil)
    project_members = project.project_members
    group_members = group ? group.group_members : []
    invited_members = []

    if project.invited_groups.any?
      project.project_group_links.each do |group_link|
        invited_group = group_link.group
        im = invited_group.group_members

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
    user_ids += invited_members.map(&:user_id) if invited_members.any?
    user_ids += group_members.pluck(:user_id) if group

    User.where(id: user_ids)
  end

  def group
    project.group
  end

  def group_member_lock
    group && group.membership_lock
  end
end
