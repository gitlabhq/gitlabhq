class FileMover
  attr_reader :secret, :file_name, :model

  def initialize(file_path, model, update_field = :description)
    @secret = File.split(File.dirname(file_path)).last
    @file_name = File.basename(file_path)
    @model = model
  end

  def execute
    move
    update_markdown
  end

  private

  def move
    FileUtils.mkdir_p(file_path)
    FileUtils.move(temp_file_path, file_path)
  end

  def update_markdown(field = :description)
    updated_text = model.send(field).sub(temp_file_uploader.to_markdown, uploader.to_markdown)
    model.update_attribute(field, updated_text)
  end

  def temp_file_path
    temp_file_uploader.retrieve_from_store!(file_name)

    temp_file_uploader.file.path
  end

  def file_path
    return @file_path if @file_path

    uploader.retrieve_from_store!(file_name)

    @file_path = uploader.file.path
  end

  def uploader
    @uploader ||= PersonalFileUploader.new(model, secret)
  end

  def temp_file_uploader
    @temp_file_uploader ||= PersonalFileUploader.new(nil, secret)
  end
end
