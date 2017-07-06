module BranchesHelper
  def filter_branches_path(options = {})
    exist_opts = {
      search: params[:search],
      sort: params[:sort]
    }

    options = exist_opts.merge(options)

    project_branches_path(@project, @id, options)
  end

  def can_push_branch?(project, branch_name)
    return false unless project.repository.branch_exists?(branch_name)

    ::Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(branch_name)
  end

  def project_branches
    options_for_select(@project.repository.branch_names, @project.default_branch)
  end

  def protected_branch?(project, branch)
    ProtectedBranch.protected?(project, branch.name)
  end

  # Returns a hash were keys are types of access levels (user, role), and
  # values are the number of access levels of the particular type.
  def access_level_frequencies(access_levels)
    access_levels.reduce(Hash.new(0)) do |frequencies, access_level|
      frequencies[access_level.type] += 1
      frequencies
    end
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
      elsif level.type == :group
        { id: level.id, type: level.type, group_id: level.group_id }
      else
        { id: level.id, type: level.type, access_level: level.access_level }
      end
    end
  end
end
