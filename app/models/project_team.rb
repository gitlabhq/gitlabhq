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

  def find(user_id)
    user = project.users.find_by(id: user_id)

    if group
      user ||= group.users.find_by(id: user_id)
    end

    user
  end

  def find_member(user_id)
    member = project.project_members.find_by(user_id: user_id)

    # If user is not in project members
    # we should check for group membership
    if group && !member
      member = group.group_members.find_by(user_id: user_id)
    end

    member
  end

  def add_users(users, access, current_user = nil)
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

  def member?(user_id)
    !!find_member(user_id)
  end

  def human_max_access(user_id)
    Gitlab::Access.options.key max_member_access(user_id)
  end

  # This method assumes project and group members are eager loaded for optimal
  # performance.
  def max_member_access(user_id)
    access = []

    project.project_members.each do |member|
      if member.user_id == user_id
        access << member.access_field if member.access_field
        break
      end
    end

    if group
      group.group_members.each do |member|
        if member.user_id == user_id
          access << member.access_field if member.access_field
          break
        end
      end
    end

    access.max
  end

  private

  def fetch_members(level = nil)
    project_members = project.project_members
    group_members = group ? group.group_members : []

    if level
      project_members = project_members.send(level)
      group_members = group_members.send(level) if group
    end

    user_ids = project_members.pluck(:user_id)
    user_ids.push(*group_members.pluck(:user_id)) if group

    User.where(id: user_ids)
  end

  def group
    project.group
  end
end
