class UploadService
  def initialize(model, file, uploader_class = FileUploader)
    @model, @file, @uploader_class = model, file, uploader_class
  end

  def execute
    return nil unless @file && @file.size <= max_attachment_size

    uploader = @uploader_class.new(@model)
    uploader.store!(@file)

    uploader.to_h
  end

  private

  def max_attachment_size
    current_application_settings.max_attachment_size.megabytes.to_i
  end
end
