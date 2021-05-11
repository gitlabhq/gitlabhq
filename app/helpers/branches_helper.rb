# frozen_string_literal: true

module BranchesHelper
  def project_branches
    options_for_select(@project.repository.branch_names, @project.default_branch)
  end

  def protected_branch?(project, branch)
    ProtectedBranch.protected?(project, branch.name)
  end

  def access_levels_data(access_levels)
    return [] unless access_levels

    access_levels.map do |level|
      if level.type == :deploy_key
        { id: level.id, type: level.type, deploy_key_id: level.deploy_key_id }
      else
        { id: level.id, type: :role, access_level: level.access_level }
      end
    end
  end
end

BranchesHelper.prepend_mod_with('BranchesHelper')
