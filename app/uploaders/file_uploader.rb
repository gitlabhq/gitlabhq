# encoding: utf-8
class FileUploader < CarrierWave::Uploader::Base
  include UploaderHelper
  MARKDOWN_PATTERN = %r{\!?\[.*?\]\(/uploads/(?<secret>[0-9a-f]{32})/(?<file>.*?)\)}

  storage :file

  attr_accessor :project, :secret

  def initialize(project, secret = nil)
    @project = project
    @secret = secret || self.class.generate_secret
  end

  def base_dir
    "uploads"
  end

  def store_dir
    File.join(base_dir, @project.path_with_namespace, @secret)
  end

  def cache_dir
    File.join(base_dir, 'tmp', @project.path_with_namespace, @secret)
  end

  def secure_url
    File.join("/uploads", @secret, file.filename)
  end

  def to_markdown
    to_h[:markdown]
  end

  def to_h
    filename = image_or_video? ? self.file.basename : self.file.filename
    escaped_filename = filename.gsub("]", "\\]")

    markdown = "[#{escaped_filename}](#{self.secure_url})"
    markdown.prepend("!") if image_or_video?

    {
      alt:      filename,
      url:      self.secure_url,
      markdown: markdown
    }
  end

  def self.generate_secret
    SecureRandom.hex
  end
end
