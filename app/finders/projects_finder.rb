class ProjectsFinder
  def execute(current_user, options = {})
    group = options[:group]

    if group
      group_projects(current_user, group)
    else
      all_projects(current_user)
    end
  end

  private

  def group_projects(current_user, group)
    if current_user
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
    else
      # Not authenticated
      #
      # Return only:
      #   public projects
      group.projects.public_only
    end
  end

  def all_projects(current_user)
    if current_user
      if current_user.authorized_projects.any?
        # User has access to private projects
        #
        # Return only:
        #   public projects
        #   internal projects
        #   joined projects
        #
        Project.where(
          "projects.id IN (?) OR projects.visibility_level IN (?)",
          current_user.authorized_projects.pluck(:id),
          Project.public_and_internal_levels
        )
      else
        # User has no access to private projects
        #
        # Return only:
        #   public projects
        #   internal projects
        #
        Project.public_and_internal_only
      end
    else
      # Not authenticated
      #
      # Return only:
      #   public projects
      Project.public_only
    end
  end
end
