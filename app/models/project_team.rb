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

  def find(user_id)
    user = project.users.find_by_id(user_id)

    if group
      user ||= group.users.find_by_id(user_id)
    end

    user
  end

  def find_tm(user_id)
    tm = project.users_projects.find_by_user_id(user_id)

    # If user is not in project members
    # we should check for group membership
    if group && !tm
      tm = group.users_groups.find_by_user_id(user_id)
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
      new_tm
    end

    UsersProject.transaction do
      source_team.each do |tm|
        tm.save
      end
    end

    true
  rescue
    false
  end

  private

  def fetch_members(level = nil)
    project_members = project.users_projects
    group_members = group ? group.users_groups : []
    invited_members = []

    if project.invited_groups.any?
      project.project_group_links.each do |group_link|
        invited_group = group_link.group
        im = invited_group.users_groups

        if level
          int_level = UsersGroup.group_access_roles[level.to_s.singularize.titleize]

          # Skip group members if we ask for masters
          # but max group access is developers
          next if int_level > group_link.group_access

          # If we ask for developers and max
          # group access is developers we need to provide
          # both group master, developers as devs
          if int_level == group_link.group_access
            im.where("group_access >= ?)", group_link.group_access)
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

    (project_members + group_members + invited_members).map(&:user).uniq
  end

  def group
    project.group
  end
end
