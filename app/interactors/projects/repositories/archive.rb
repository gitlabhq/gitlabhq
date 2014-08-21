module Projects::Repositories
  class Archive < Projects::Base
    def setup
      context.fail!(message: "Invalid ref") if context[:ref].blank?
    end

    def perform
      project = context[:project]
      ref = context[:ref]
      format = context[:format]

      storage_path = Gitlab.config.gitlab.repository_downloads_path

      unless File.directory?(storage_path)
        FileUtils.mkdir_p(storage_path)
      end

      format ||= 'tar.gz'
      repository = project.repository
      repository.clean_old_archives
      file_path = repository.archive_repo(ref, storage_path, format.downcase)
      context[:file_path] = file_path
    end

    def rollback
    end
  end
end
