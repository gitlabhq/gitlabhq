# encoding: utf-8
class FileUploader < CarrierWave::Uploader::Base
  include UploaderHelper

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
end
