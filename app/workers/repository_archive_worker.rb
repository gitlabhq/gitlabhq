class RepositoryArchiveWorker
  include Sidekiq::Worker

  sidekiq_options queue: :archive_repo

  attr_accessor :project, :ref, :format

  def perform(project_id, ref, format)
    @project = Project.find(project_id)
    @ref, @format = ref, format

    repository = project.repository

    repository.clean_old_archives

    return if archived? || archiving?

    repository.archive_repo(*archive_args)
  end

  private

  def storage_path
    Gitlab.config.gitlab.repository_downloads_path
  end

  def archive_args
    @archive_args ||= [ref, storage_path, format.downcase]
  end

  def file_path
    @file_path ||= project.repository.archive_file_path(*archive_args)
  end

  def pid_file_path
    @pid_file_path ||= project.repository.archive_pid_file_path(*archive_args)
  end

  def archived?
    File.exist?(file_path)
  end

  def archiving?
    File.exist?(pid_file_path)
  end
end
