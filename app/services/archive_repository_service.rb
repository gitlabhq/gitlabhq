class ArchiveRepositoryService
  attr_reader :project, :ref, :format

  def initialize(project, ref, format)
    format ||= 'tar.gz'
    @project, @ref, @format = project, ref, format.downcase
  end

  def execute(options = {})
    RepositoryArchiveCacheWorker.perform_async

    metadata = project.repository.archive_metadata(ref, storage_path, format)
    raise "Repository or ref not found" if metadata.empty?

    metadata
  end

  private

  def storage_path
    Gitlab.config.gitlab.repository_downloads_path
  end
end
