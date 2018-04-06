class ProjectTeam
  include BulkMemberAccessLoad

  prepend EE::ProjectTeam

  attr_accessor :project

  def initialize(project)
    @project = project
  end

  def add_guest(user, current_user: nil)
    add_user(user, :guest, current_user: current_user)
  end

  def add_reporter(user, current_user: nil)
    add_user(user, :reporter, current_user: current_user)
  end

  def add_developer(user, current_user: nil)
    add_user(user, :developer, current_user: current_user)
  end

  def add_master(user, current_user: nil)
    add_user(user, :master, current_user: current_user)
  end

  def add_role(user, role, current_user: nil)
    public_send(:"add_#{role}", user, current_user: current_user) # rubocop:disable GitlabSecurity/PublicSend
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

  def add_users(users, access_level, current_user: nil, expires_at: nil)
    ProjectMember.add_users(
      project,
      users,
      access_level,
      current_user: current_user,
      expires_at: expires_at
    )
  end

  def add_user(user, access_level, current_user: nil, expires_at: nil)
    ProjectMember.add_user(
      project,
      user,
      access_level,
      current_user: current_user,
      expires_at: expires_at
    )
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
    @guests ||= fetch_members(Gitlab::Access::GUEST)
  end

  def reporters
    @reporters ||= fetch_members(Gitlab::Access::REPORTER)
  end

  def developers
    @developers ||= fetch_members(Gitlab::Access::DEVELOPER)
  end

  def masters
    @masters ||= fetch_members(Gitlab::Access::MASTER)
  end

  def owners
    @owners ||=
      if group
        group.owners
      else
        [project.owner]
      end
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

  # Checks if `user` is authorized for this project, with at least the
  # `min_access_level` (if given).
  def member?(user, min_access_level = Gitlab::Access::GUEST)
    return false unless user

    max_member_access(user.id) >= min_access_level
  end

  def human_max_access(user_id)
    Gitlab::Access.human_access(max_member_access(user_id))
  end

  # Determine the maximum access level for a group of users in bulk.
  #
  # Returns a Hash mapping user ID -> maximum access level.
  def max_member_access_for_user_ids(user_ids)
    max_member_access_for_resource_ids(User, user_ids, project.id) do |user_ids|
      project.project_authorizations
             .where(user: user_ids)
             .group(:user_id)
             .maximum(:access_level)
    end
  end

  def max_member_access(user_id)
    max_member_access_for_user_ids([user_id])[user_id]
  end

  private

  def fetch_members(level = nil)
    members = project.authorized_users
    members = members.where(project_authorizations: { access_level: level }) if level

    members
  end

  def group
    project.group
  end
end
