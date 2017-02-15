class FileUploader < GitlabUploader
  include RecordsUploads
  include UploaderHelper

  MARKDOWN_PATTERN = %r{\!?\[.*?\]\(/uploads/(?<secret>[0-9a-f]{32})/(?<file>.*?)\)}

  storage :file

  attr_accessor :project
  attr_reader :secret

  def initialize(project, secret = nil)
    @project = project
    @secret = secret || generate_secret
  end

  def store_dir
    File.join(base_dir, @project.path_with_namespace, @secret)
  end

  def cache_dir
    File.join(base_dir, 'tmp', @project.path_with_namespace, @secret)
  end

  def model
    project
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

  def generate_secret
    SecureRandom.hex
  end

  def secure_url
    File.join('/uploads', @secret, file.filename)
  end
end
