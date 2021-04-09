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

  def gldropdrown_branches_enabled?
    Feature.enabled?(:gldropdown_branches, default_enabled: :yaml)
  end
end

BranchesHelper.prepend_if_ee('EE::BranchesHelper')
