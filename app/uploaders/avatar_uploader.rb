# encoding: utf-8

class AvatarUploader < CarrierWave::Uploader::Base
  include UploaderHelper
  include CarrierWave::MiniMagick

  storage :file

  after :store, :reset_events_cache

  process :cropper

  def cropper
    return unless model.respond_to?(:avatar_crop_size) && model.valid?

    manipulate! do |img|
      img.crop "#{model.avatar_crop_size}x#{model.avatar_crop_size}+#{model.avatar_crop_x}+#{model.avatar_crop_y}"
    end
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def reset_events_cache(file)
    model.reset_events_cache if model.is_a?(User)
  end
end
