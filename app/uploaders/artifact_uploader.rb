# encoding: utf-8
class ArtifactUploader < CarrierWave::Uploader::Base
  storage :file

  attr_accessor :build, :field

  def self.artifacts_path
    File.expand_path('shared/artifacts/', Rails.root)
  end

  def self.artifacts_upload_path
    File.expand_path('shared/artifacts/tmp/uploads/', Rails.root)
  end

  def self.artifacts_cache_path
    File.expand_path('shared/artifacts/tmp/cache/', Rails.root)
  end

  def initialize(build, field)
    @build, @field = build, field
  end

  def artifacts_path
    File.join(build.created_at.utc.strftime('%Y_%m'), build.project.id.to_s, build.id.to_s)
  end

  def store_dir
    File.join(ArtifactUploader.artifacts_path, artifacts_path)
  end

  def cache_dir
    File.join(ArtifactUploader.artifacts_cache_path, artifacts_path)
  end

  def file_storage?
    self.class.storage == CarrierWave::Storage::File
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
