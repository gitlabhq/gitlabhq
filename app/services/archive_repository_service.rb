class ArchiveRepositoryService
  attr_reader :project, :ref, :format

  def initialize(project, ref, format)
    format ||= 'tar.gz'
    @project, @ref, @format = project, ref, format.downcase
  end

  def execute(options = {})
    project.repository.clean_old_archives

    raise "No archive file path" unless file_path

    return file_path if archived?

    unless archiving?
      RepositoryArchiveWorker.perform_async(project.id, ref, format)
    end

    archived = wait_until_archived(options[:timeout] || 5.0)

    file_path if archived
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

  def wait_until_archived(timeout = 5.0)
    return archived? if timeout == 0.0
    
    t1 = Time.now

    begin
      sleep 0.1

      success = archived?

      t2 = Time.now
    end until success || t2 - t1 >= timeout

    success
  end
end
