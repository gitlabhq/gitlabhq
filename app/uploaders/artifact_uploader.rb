# encoding: utf-8
class ArtifactUploader < CarrierWave::Uploader::Base
  storage :file

  attr_accessor :build, :field

  def self.artifacts_path
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.artifacts_path, 'tmp/uploads/')
  end

  def self.artifacts_cache_path
    File.join(self.artifacts_path, 'tmp/cache/')
  end

  def initialize(build, field)
    @build, @field = build, field
  end

  def store_dir
    File.join(self.class.artifacts_path, @build.artifacts_path)
  end

  def cache_dir
    File.join(self.class.artifacts_cache_path, @build.artifacts_path)
  end

  def file_storage?
    self.class.storage == CarrierWave::Storage::File
  end

  def filename
    file.try(:filename)
  end

  def exists?
    file.try(:exists?)
  end

  def move_to_cache
    true
  end

  def move_to_store
    true
  end
end
