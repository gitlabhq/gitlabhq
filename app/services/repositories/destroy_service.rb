# frozen_string_literal: true

class Repositories::DestroyService < Repositories::BaseService
  def execute
    return success unless repository
    return success unless repo_exists?(disk_path)

    # Flush the cache for both repositories. This has to be done _before_
    # removing the physical repositories as some expiration code depends on
    # Git data (e.g. a list of branch names).
    ignore_git_errors { repository.before_delete }

    if mv_repository(disk_path, removal_path)
      log_info(%Q{Repository "#{disk_path}" moved to "#{removal_path}" for repository "#{full_path}"})

      current_repository = repository
      project.run_after_commit do
        Repositories::ShellDestroyService.new(current_repository).execute
      end

      log_info("Project \"#{project.full_path}\" was removed")

      success
    else
      move_error(disk_path)
    end
  end
end
