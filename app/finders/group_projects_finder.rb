class GroupProjectsFinder < UnionFinder
  def initialize(group, options = {})
    @group   = group
    @options = options
  end

  def execute(current_user = nil)
    segments = group_projects(current_user)
    find_union(segments, Project)
  end

  private

  def group_projects(current_user)
    only_owned  = @options.fetch(:only_owned, false)
    only_shared = @options.fetch(:only_shared, false)

    projects = []

    if current_user
      if @group.users.include?(current_user)
        projects << @group.projects unless only_shared
        projects << @group.shared_projects unless only_owned
      else
        unless only_shared
          projects << @group.projects.visible_to_user(current_user)
          projects << @group.projects.public_to_user(current_user)
        end

        unless only_owned
          projects << @group.shared_projects.visible_to_user(current_user)
          projects << @group.shared_projects.public_to_user(current_user)
        end
      end
    else
      projects << @group.projects.public_only unless only_shared
      projects << @group.shared_projects.public_only unless only_owned
    end

    projects
  end
end
