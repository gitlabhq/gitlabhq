module BranchesHelper
  prepend EE::BranchesHelper

  def project_branches
    options_for_select(@project.repository.branch_names, @project.default_branch)
  end

  def protected_branch?(project, branch)
    ProtectedBranch.protected?(project, branch.name)
  end

  def diverging_count_label(count)
    if count >= Repository::MAX_DIVERGING_COUNT
      "#{Repository::MAX_DIVERGING_COUNT - 1}+"
    else
      count.to_s
    end
  end
end
