# frozen_string_literal: true

module Branches
  class DeleteService < BaseService
    def execute(branch_name)
      repository = project.repository

      unless current_user.can?(:push_code, project)
        return ServiceResponse.error(
          message: 'You dont have push access to repo',
          http_status: 405)
      end

      return missing_branch_error if branch_name.blank?

      branch = repository.find_branch(branch_name)

      return missing_branch_error unless branch

      target_sha = branch.dereferenced_target.id

      if repository.rm_branch(current_user, branch_name, target_sha: target_sha)
        unlock_artifacts(branch_name)
        ServiceResponse.success(message: 'Branch was deleted')
      else
        ServiceResponse.error(
          payload: { branch: branch },
          message: 'Failed to remove branch',
          http_status: 400)
      end
    rescue Gitlab::Git::PreReceiveError, Gitlab::Git::CommandError => ex
      ServiceResponse.error(payload: { branch: branch }, message: ex.message, http_status: 400)
    end

    private

    def missing_branch_error
      ServiceResponse.error(message: 'No such branch', http_status: 404)
    end

    def unlock_artifacts(branch_name)
      Ci::RefDeleteUnlockArtifactsWorker.perform_async(project.id, current_user.id, "#{::Gitlab::Git::BRANCH_REF_PREFIX}#{branch_name}")
    end
  end
end

Branches::DeleteService.prepend_mod
