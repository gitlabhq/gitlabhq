module BranchesHelper
  def can_remove_branch?(project, branch_name)
    if project.protected_branch? branch_name
      false
    elsif branch_name == project.repository.root_ref
      false
    else
      can?(current_user, :push_code, project)
    end
  end

  def filter_branches_path(options = {})
    exist_opts = {
      search: params[:search],
      sort: params[:sort]
    }

    options = exist_opts.merge(options)

    namespace_project_branches_path(@project.namespace, @project, @id, options)
  end

  def can_push_branch?(project, branch_name)
    return false unless project.repository.branch_exists?(branch_name)

    ::Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(branch_name)
  end

  def project_branches
    options_for_select(@project.repository.branch_names, @project.default_branch)
  end

  def access_levels_data(access_levels)
    access_levels.map do |level|
      if level.type == :user
        {
          id: level.id,
          type: level.type,
          user_id: level.user_id,
          username: level.user.username,
          name: level.user.name,
          avatar_url: level.user.avatar_url
        }
      else
        { id: level.id, type: level.type, access_level: level.access_level }
      end
    end
  end
end
