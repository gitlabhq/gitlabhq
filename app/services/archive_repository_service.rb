class ArchiveRepositoryService
  def execute(project, ref, format)
    storage_path = Gitlab.config.gitlab.repository_downloads_path

    unless File.directory?(storage_path)
      FileUtils.mkdir_p(storage_path)
    end

    format ||= 'tar.gz'
    repository = project.repository
    repository.clean_old_archives
    repository.archive_repo(ref, storage_path, format.downcase)
  end
end
