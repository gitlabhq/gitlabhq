# encoding: utf-8
class FileUploader < CarrierWave::Uploader::Base
  storage :file

  def initialize(path, allowed_extensions = nil)
    @path = path
    @allowed_extensions = allowed_extensions
  end

  def store_dir
    @path
  end

  def extension_white_list
    @allowed_extensions
  end

  def store!(file)
    original_filename = file.original_filename
    generate_filename(file)
    super
    original_filename
  end

  def generate_filename(file)
    new_filename = Digest::MD5.hexdigest(file.original_filename)
    file.original_filename = new_filename + File.extname(file.original_filename)
  end
end
