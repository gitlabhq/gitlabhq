# encoding: utf-8
class FileUploader < CarrierWave::Uploader::Base
  storage :file

  attr_accessor :project, :secret

  def initialize(project, secret = self.class.generate_secret)
    @project = project
    @secret = secret
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

  def self.generate_secret
    SecureRandom.hex
  end

  def secure_url
    File.join("/uploads", @secret, file.filename)
  end

  def file_storage?
    self.class.storage == CarrierWave::Storage::File
  end

  def image?
    img_ext = %w(png jpg jpeg gif bmp tiff)
    if file.respond_to?(:extension)
      img_ext.include?(file.extension.downcase)
    else
      # Not all CarrierWave storages respond to :extension
      ext = file.path.split('.').last.downcase
      img_ext.include?(ext)
    end
  rescue
    false
  end
end
