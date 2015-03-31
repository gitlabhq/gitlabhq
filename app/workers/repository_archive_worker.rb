class RepositoryArchiveWorker
  include Sidekiq::Worker

  sidekiq_options queue: :archive_repo

  attr_accessor :project, :ref, :format

  def perform(project_id, ref, format)
    @project = Project.find(project_id)
    @ref, @format = ref, format.downcase

    repository = project.repository

    repository.clean_old_archives

    return unless file_path
    return if archived? || archiving?

    repository.archive_repo(ref, storage_path, format)
  end

  private

  def storage_path
    Gitlab.config.gitlab.repository_downloads_path
  end

  def file_path
    @file_path ||= project.repository.archive_file_path(ref, storage_path, format)
  end

  def pid_file_path
    @pid_file_path ||= project.repository.archive_pid_file_path(ref, storage_path, format)
  end

  def archived?
    File.exist?(file_path)
  end

  def archiving?
    File.exist?(pid_file_path)
  end
end
