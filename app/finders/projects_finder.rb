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
      base, extra = group_projects(current_user, group)
    else
      base, extra = all_projects(current_user)
    end

    if base and extra
      union = Gitlab::SQL::Union.new([base.select(:id), extra.select(:id)])

      Project.where("projects.id IN (#{union.to_sql})")
    else
      base
    end
  end

  private

  def group_projects(current_user, group)
    if current_user
<<<<<<< HEAD
      if group.users.include?(current_user)
        # User is group member
        #
        # Return ALL group projects
        group.projects
      else
        projects_members = ProjectMember.in_projects(group.projects).
          with_user(current_user)

        if projects_members.any?
          # User is a project member
          #
          # Return only:
          #   public projects
          #   internal projects
          #   joined projects
          #
          group.projects.where(
            "projects.id IN (?) OR projects.visibility_level IN (?)",
            projects_members.pluck(:source_id),
            Project.public_and_internal_levels
          )
        else
          # User has no access to group or group projects
          # or has access through shared project
          #
          # Return only:
          #   public projects
          #   internal projects
          #   shared projects
          projects_ids = []
          ProjectGroupLink.where(project_id: group.projects).each do |shared_project|
            if shared_project.group.users.include?(current_user) || shared_project.project.users.include?(current_user)
              projects_ids << shared_project.project.id
            end
          end

          group.projects.where(
            "projects.id IN (?) OR projects.visibility_level IN (?)",
            projects_ids,
            Project.public_and_internal_levels
          )
        end
      end
=======
      [
        group_projects_for_user(current_user, group),
        group.projects.public_and_internal_only
      ]
>>>>>>> b6f0eddce552d7423869e9072a7a0706e309dbdf
    else
      [group.projects.public_only]
    end
  end

  def all_projects(current_user)
    if current_user
      [current_user.authorized_projects, public_and_internal_projects]
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
