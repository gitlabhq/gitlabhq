class ProjectsFinder
  # Returns all projects, optionally including group projects a user has access
  # to.
  #
  # ## Examples
  #
  # Retrieving all public projects:
  #
  #     ProjectsFinder.new.execute
  #
  # Retrieving all public/internal projects and those the given user has access
  # to:
  #
  #     ProjectsFinder.new.execute(some_user)
  #
  # Retrieving all public/internal projects as well as the group's projects the
  # user has access to:
  #
  #     ProjectsFinder.new.execute(some_user, group: some_group)
  #
  # Returns an ActiveRecord::Relation.
  def execute(current_user = nil, options = {})
    group = options[:group]

    if group
      segments = group_projects(current_user, group)
    else
      segments = all_projects(current_user)
    end

    if segments.length > 1
      union = Gitlab::SQL::Union.new(segments.map { |s| s.select(:id) })

      Project.where("projects.id IN (#{union.to_sql})")
    else
      segments.first
    end
  end

  private

  def group_projects(current_user, group)
    if current_user
      [
        group_projects_for_user(current_user, group),
        group.projects.public_and_internal_only
      ]
    else
      [group.projects.public_only]
    end
  end

  def all_projects(current_user)
    if current_user
      [
        current_user.authorized_projects,
        public_and_internal_projects
      ]
    else
      [Project.public_only]
    end
  end

  def group_projects_for_user(current_user, group)
    if group.users.include?(current_user)
      group.projects
    else
      group.projects.visible_to_user(current_user)
    end
  end

  def public_projects
    Project.unscoped.public_only
  end

  def public_and_internal_projects
    Project.unscoped.public_and_internal_only
  end
end
