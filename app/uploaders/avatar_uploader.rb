# encoding: utf-8

class AvatarUploader < CarrierWave::Uploader::Base
  include UploaderHelper

  storage :file

  after :store, :reset_events_cache

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def reset_events_cache(file)
    model.reset_events_cache if model.is_a?(User)
  end
end
