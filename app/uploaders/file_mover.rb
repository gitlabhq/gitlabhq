class FileMover
  attr_reader :secret, :file_name, :model, :update_field

  def initialize(file_path, model, update_field = :description)
    @secret = File.split(File.dirname(file_path)).last
    @file_name = File.basename(file_path)
    @model = model
    @update_field = update_field
  end

  def execute
    move
    uploader.record_upload if update_markdown
  end

  private

  def move
    FileUtils.mkdir_p(File.dirname(file_path))
    FileUtils.move(temp_file_path, file_path)
  end

  def update_markdown
    updated_text = model.read_attribute(update_field)
                        .gsub(temp_file_uploader.markdown_link, uploader.markdown_link)
    model.update_attribute(update_field, updated_text)

    true
  rescue
    revert

    false
  end

  def temp_file_path
    return @temp_file_path if @temp_file_path

    temp_file_uploader.retrieve_from_store!(file_name)

    @temp_file_path = temp_file_uploader.file.path
  end

  def file_path
    return @file_path if @file_path

    uploader.retrieve_from_store!(file_name)

    @file_path = uploader.file.path
  end

  def uploader
    @uploader ||= PersonalFileUploader.new(model, secret: secret)
  end

  def temp_file_uploader
    @temp_file_uploader ||= PersonalFileUploader.new(nil, secret: secret)
  end

  def revert
    Rails.logger.warn("Markdown not updated, file move reverted for #{model}")

    FileUtils.move(file_path, temp_file_path)
  end
end
