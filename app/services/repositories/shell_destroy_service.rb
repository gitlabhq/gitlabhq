# frozen_string_literal: true

class Repositories::ShellDestroyService < Repositories::BaseService
  REPO_REMOVAL_DELAY = 5.minutes.to_i
  STALE_REMOVAL_DELAY = REPO_REMOVAL_DELAY * 2

  def execute(delay = REPO_REMOVAL_DELAY)
    return success unless repository

    GitlabShellWorker.perform_in(delay,
                                 :remove_repository,
                                 repository.shard,
                                 removal_path)
  end
end
