# frozen_string_literal: true

class ResetProjectCacheService < BaseService
  def execute
    result = project.increment!(:jobs_cache_index)

    audit_runner_cache_cleared

    result
  end

  private

  def audit_runner_cache_cleared
    ::Gitlab::Audit::Auditor.audit(
      name: 'project_runner_cache_cleared',
      author: current_user,
      scope: project,
      target: project,
      message: 'Cleared the runner cache for the project',
      additional_details: { jobs_cache_index: project.jobs_cache_index }
    )
  end
end
