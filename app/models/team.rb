class Team
  attr_accessor :project

  def initialize(project)
    @project = project
    @roles = UsersProject.roles_hash
  end

  def add_user(user, access)
    add_users_ids([user.id], access)
  end

  def add_users(users, access)
    add_users_ids(users.map(&:id), access)
  end

  def add_users_ids(users_ids, access)
    UsersProject.add_users_into_projects(
      [project.id],
      user_ids,
      access
    )
  end

  # Remove all users from project team
  def truncate
    UsersProject.truncate_team(project)
  end

  def members
    project.users_projects
  end

  def guests
    members.guests.map(&:user)
  end

  def reporters
    members.reporters.map(&:user)
  end

  def developers
    members.developers.map(&:user)
  end

  def masters
    members.masters.map(&:user)
  end
end
