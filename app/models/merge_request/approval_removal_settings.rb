# frozen_string_literal: true

class MergeRequest::ApprovalRemovalSettings # rubocop:disable Style/ClassAndModuleChildren
  include ActiveModel::Validations

  attr_accessor :project

  validate :mutually_exclusive_settings

  def initialize(project, reset_approvals_on_push, selective_code_owner_removals)
    @project = project
    @reset_approvals_on_push = reset_approvals_on_push
    @selective_code_owner_removals = selective_code_owner_removals
  end

  private

  def selective_code_owner_removals
    if @selective_code_owner_removals.nil?
      project.project_setting.selective_code_owner_removals
    else
      @selective_code_owner_removals
    end
  end

  def reset_approvals_on_push
    if @reset_approvals_on_push.nil?
      project.reset_approvals_on_push
    else
      @reset_approvals_on_push
    end
  end

  def mutually_exclusive_settings
    return unless selective_code_owner_removals && reset_approvals_on_push

    errors.add(:base, 'selective_code_owner_removals can only be enabled when reset_approvals_on_push is disabled')
  end
end
