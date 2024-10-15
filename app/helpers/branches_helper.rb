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

    access_levels.filter_map do |level|
      case level.type
      when :role
        { id: level.id, type: :role, access_level: level.access_level }
      when :deploy_key
        { id: level.id, type: level.type, deploy_key_id: level.deploy_key_id }
      end
    end
  end

  def merge_request_status(merge_request)
    return unless merge_request.present?

    if merge_request.closed?
      variant = :danger
      mr_icon = 'merge-request-close'
      mr_status = _('Closed')
    elsif merge_request.open? || merge_request.locked?
      variant = :success
      variant = :warning if merge_request.draft?

      mr_icon = 'merge-request'
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
