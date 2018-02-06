# This service is an adapter used to for the GitLab Import feature, and
# creating a project from a template.
# The latter will under the hood just import an archive supplied by GitLab.
module Projects
  class GitlabProjectsImportService
    attr_reader :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      FileUtils.mkdir_p(File.dirname(import_upload_path))
      FileUtils.copy_entry(file.path, import_upload_path)

      Gitlab::ImportExport::ProjectCreator.new(params[:namespace_id],
                                               current_user,
                                               import_upload_path,
                                               params[:path]).execute
    end

    private

    def import_upload_path
      @import_upload_path ||= Gitlab::ImportExport.import_upload_path(filename: tmp_filename)
    end

    def tmp_filename
      SecureRandom.hex
    end

    def file
      params[:file]
    end
  end
end
