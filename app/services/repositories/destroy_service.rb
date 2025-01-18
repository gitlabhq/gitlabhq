# frozen_string_literal: true

class Repositories::DestroyService < ::Repositories::BaseService
  def execute
    return success unless repository
    return success unless repo_exists?(disk_path)

    # Flush the cache for both repositories. This has to be done _before_
    # removing the physical repositories as some expiration code depends on
    # Git data (e.g. a list of branch names).
    ignore_git_errors { repository.before_delete }

    # Use variables that aren't methods on Project, because they are used in a callback
    current_storage = repository.shard
    current_path = "#{disk_path}.git"

    # Because #remove happens inside a run_after_commit callback it will
    # never be triggered on a read-only instance.
    #
    # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/223272
    if Gitlab::Database.read_only?
      Gitlab::Git::Repository.new(current_storage, current_path, nil, nil).remove
    else
      container.run_after_commit do
        Gitlab::Git::Repository.new(current_storage, current_path, nil, nil).remove
      end
    end

    log_info("Repository \"#{full_path}\" was removed")

    success
  rescue Gitlab::Git::Repository::NoRepository
    success
  end
end
