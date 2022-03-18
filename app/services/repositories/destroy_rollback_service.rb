# frozen_string_literal: true

class Repositories::DestroyRollbackService < Repositories::BaseService
  def execute
    # There is a possibility project does not have repository or wiki
    return success unless repo_exists?(removal_path)

    # Flush the cache for both repositories.
    ignore_git_errors { repository.before_delete }

    if mv_repository(removal_path, disk_path)
      log_info(%Q{Repository "#{removal_path}" moved to "#{disk_path}" for repository "#{full_path}"})

      success
    elsif repo_exists?(removal_path)
      # If the repo does not exist, there is no need to return an
      # error because there was nothing to do.
      move_error(removal_path)
    else
      success
    end
  rescue Gitlab::Git::Repository::NoRepository
    success
  end
end
