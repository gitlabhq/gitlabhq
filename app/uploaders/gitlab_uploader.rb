class GitlabUploader < CarrierWave::Uploader::Base
  def self.base_dir
    'uploads'
  end

  delegate :base_dir, to: :class

  def file_storage?
    self.class.storage == CarrierWave::Storage::File
  end

  # Reduce disk IO
  def move_to_cache
    true
  end

  # Reduce disk IO
  def move_to_store
    true
  end
end
