# frozen_string_literal: true

class Repositories::BaseService < BaseService
  include Gitlab::ShellAdapter

  attr_reader :repository

  delegate :container, :disk_path, :full_path, to: :repository

  def initialize(repository)
    @repository = repository
  end

  def repo_exists?(path)
    gitlab_shell.repository_exists?(repository.shard, path + '.git')
  end

  def mv_repository(from_path, to_path)
    gitlab_shell.mv_repository(repository.shard, from_path, to_path)
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
