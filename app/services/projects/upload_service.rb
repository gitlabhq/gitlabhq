module Projects
  class UploadService < BaseService
    include Rails.application.routes.url_helpers
    def initialize(project, file)
      @project, @file = project, file
    end

    def execute
      return nil unless @file

      uploader = FileUploader.new(@project)
      uploader.store!(@file)

      filename = uploader.image? ? uploader.file.basename : uploader.file.filename

      {
        'alt'       => filename,
        'url'       => project_upload_url(@project, secret: uploader.secret, filename: uploader.file.filename),
        'is_image'  => uploader.image?
      }
    end
  end
end
