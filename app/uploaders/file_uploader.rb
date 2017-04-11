class FileUploader < GitlabUploader
  include RecordsUploads
  include UploaderHelper

  MARKDOWN_PATTERN = %r{\!?\[.*?\]\(/uploads/(?<secret>[0-9a-f]{32})/(?<file>.*?)\)}

  storage :file

  def self.absolute_path(upload_record)
    File.join(
      self.dynamic_path_segment(upload_record.model),
      upload_record.path
    )
  end

  # Returns the part of `store_dir` that can change based on the model's current
  # path
  #
  # This is used to build Upload paths dynamically based on the model's current
  # namespace and path, allowing us to ignore renames or transfers.
  #
  # model - Object that responds to `path_with_namespace`
  #
  # Returns a String without a trailing slash
  def self.dynamic_path_segment(model)
    File.join(CarrierWave.root, base_dir, model.path_with_namespace)
  end

  attr_accessor :project
  attr_reader :secret

  def initialize(project, secret = nil)
    @project = project
    @secret = secret || generate_secret
  end

  def store_dir
    File.join(dynamic_path_segment, @secret)
  end

  def model
    project
  end

  def relative_path
    self.file.path.sub("#{dynamic_path_segment}/", '')
  end

  def to_markdown
    to_h[:markdown]
  end

  def to_h
    filename = image_or_video? ? self.file.basename : self.file.filename
    escaped_filename = filename.gsub("]", "\\]")

    markdown = "[#{escaped_filename}](#{secure_url})"
    markdown.prepend("!") if image_or_video? || dangerous?

    {
      alt:      filename,
      url:      secure_url,
      markdown: markdown
    }
  end

  private

  def dynamic_path_segment
    self.class.dynamic_path_segment(model)
  end

  def generate_secret
    SecureRandom.hex
  end

  def secure_url
    File.join('/uploads', @secret, file.filename)
  end
end
