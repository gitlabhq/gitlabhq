module Projects
  class UploadService < BaseService
    def initialize(project, file)
      @project, @file = project, file
    end

    def execute
      return nil unless @file and @file.size <= max_attachment_size

      uploader = FileUploader.new(@project)
      uploader.store!(@file)

      uploader.to_h
    end

    private

    def max_attachment_size
      current_application_settings.max_attachment_size.megabytes.to_i
    end
  end
end
