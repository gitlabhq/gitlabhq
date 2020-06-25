# frozen_string_literal: true

class Repositories::BaseService < BaseService
  include Gitlab::ShellAdapter

  DELETED_FLAG = '+deleted'

  attr_reader :repository

  delegate :container, :disk_path, :full_path, to: :repository

  def initialize(repository)
    @repository = repository
  end

  def repo_exists?(path)
    gitlab_shell.repository_exists?(repository.shard, path + '.git')
  end

  def mv_repository(from_path, to_path)
    return true unless repo_exists?(from_path)

    gitlab_shell.mv_repository(repository.shard, from_path, to_path)
  end

  # Build a path for removing repositories
  # We use `+` because its not allowed by GitLab so user can not create
  # project with name cookies+119+deleted and capture someone stalled repository
  #
  # gitlab/cookies.git -> gitlab/cookies+119+deleted.git
  #
  def removal_path
    "#{disk_path}+#{container.id}#{DELETED_FLAG}"
  end

  # If we get a Gitaly error, the repository may be corrupted. We can
  # ignore these errors since we're going to trash the repositories
  # anyway.
  def ignore_git_errors(&block)
    yield
  rescue Gitlab::Git::CommandError => e
    Gitlab::GitLogger.warn(class: self.class.name, container_id: container.id, disk_path: disk_path, message: e.to_s)
  end

  def move_error(path)
    error = %Q{Repository "#{path}" could not be moved}

    log_error(error)
    error(error)
  end
end
