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

  def merge_request_status(merge_request)
    return unless merge_request.present?
    return if merge_request.closed?

    if merge_request.open? || merge_request.locked?
      variant = :success
      variant = :warning if merge_request.draft?

      mr_icon = 'merge-request-open'
      mr_status = _('Open')
    elsif merge_request.merged?
      variant = :info
      mr_icon = 'merge'
      mr_status = _('Merged')
    else
      return
    end

    { icon: mr_icon, title: "#{mr_status} - #{merge_request.title}", variant: variant }
  end
end

BranchesHelper.prepend_mod_with('BranchesHelper')
