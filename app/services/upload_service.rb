# frozen_string_literal: true

class UploadService
  # Temporarily introduced for upload API: https://gitlab.com/gitlab-org/gitlab/-/issues/325788
  attr_accessor :override_max_attachment_size

  def initialize(model, file, uploader_class = FileUploader, **uploader_context)
    @model = model
    @file = file
    @uploader_class = uploader_class
    @uploader_context = uploader_context
  end

  def execute
    return unless file && file.size <= max_attachment_size

    uploader = uploader_class.new(model, nil, **uploader_context)
    uploader.store!(file)

    uploader
  end

  private

  attr_reader :model, :file, :uploader_class, :uploader_context

  def max_attachment_size
    override_max_attachment_size || Gitlab::CurrentSettings.max_attachment_size.megabytes.to_i
  end
end
