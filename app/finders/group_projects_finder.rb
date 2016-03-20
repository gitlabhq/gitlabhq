class GroupProjectsFinder < UnionFinder
  def initialize(group, options = {})
    @group = group
    @options = options
  end

  def execute(current_user = nil)
    segments = group_projects(current_user)

    find_union(segments, Project)
  end

  private

  def group_projects(current_user)
    include_owned = @options.fetch(:owned, true)
    include_shared = @options.fetch(:shared, true)

    projects = []

    if current_user
      if @group.users.include?(current_user)
        projects << @group.projects if include_owned
        projects << @group.shared_projects if include_shared
      else
        if include_owned
          projects << @group.projects.visible_to_user(current_user)
          projects << @group.projects.public_to_user(current_user)
        end

        if include_shared
          projects << @group.shared_projects.visible_to_user(current_user)
          projects << @group.shared_projects.public_to_user(current_user)
        end
      end
    else
      projects << @group.projects.public_only if include_owned
      projects << @group.shared_projects.public_only if include_shared
    end

    projects
  end
end
