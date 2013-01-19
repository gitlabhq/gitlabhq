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
  def << args
    users = args.first

    if users.respond_to?(:each)
      add_users(users, args.second)
    else
      add_user(users, args.second)
    end
  end

  def get_tm user_id
    project.users_projects.find_by_user_id(user_id)
  end

  def add_user(user, access)
    add_users_ids([user.id], access)
  end

  def add_users(users, access)
    add_users_ids(users.map(&:id), access)
  end

  def add_users_ids(user_ids, access)
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

  def repository_readers
    repository_members[UsersProject::REPORTER]
  end

  def repository_writers
    repository_members[UsersProject::DEVELOPER]
  end

  def repository_masters
    repository_members[UsersProject::MASTER]
  end

  def repository_members
    keys = Hash.new {|h,k| h[k] = [] }
    UsersProject.select("keys.identifier, project_access").
        joins(user: :keys).where(project_id: project.id).
        each {|row| keys[row.project_access] << [row.identifier] }

    keys[UsersProject::REPORTER] += project.deploy_keys.pluck(:identifier)
    keys
  end

  def import(source_project)
    target_project = project

    source_team = source_project.users_projects.all
    target_team = target_project.users_projects.all
    target_user_ids = target_team.map(&:user_id)

    source_team.reject! do |tm|
      # Skip if user already present in team
      target_user_ids.include?(tm.user_id)
    end

    source_team.map! do |tm|
      new_tm = tm.dup
      new_tm.id = nil
      new_tm.project_id = target_project.id
      new_tm.skip_git = true
      new_tm
    end

    UsersProject.transaction do
      source_team.each do |tm|
        tm.save
      end
      target_project.update_repository
    end

    true
  rescue
    false
  end
end
