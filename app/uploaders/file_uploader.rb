# encoding: utf-8
class FileUploader < CarrierWave::Uploader::Base
  storage :file

  def initialize(base_dir, path = '', allowed_extensions = nil)
    @base_dir = base_dir
    @path = path
    @allowed_extensions = allowed_extensions
  end

  def base_dir
    @base_dir
  end

  def store_dir
    File.join(@base_dir, @path)
  end

  def cache_dir
    File.join(@base_dir, 'tmp', @path)
  end

  def extension_white_list
    @allowed_extensions
  end

  def store!(file)
    @filename = self.class.generate_filename(file)
    super
  end

  def self.generate_filename(file)
    original_filename = File.basename(file.original_filename, '.*')
    extension = File.extname(file.original_filename)
    new_filename = Digest::MD5.hexdigest(original_filename) + extension
  end

  def self.generate_dir
    SecureRandom.hex(5)
  end
end
