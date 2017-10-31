class CustomEmojiUploader < GitlabUploader
  include RecordsUploads
  include UploaderHelper

  storage :file

  def store_dir
    "#{base_dir}/#{model.class.to_s.underscore}/#{model.namespace.full_path}/#{model.id}"
  end

  def move_to_store
    false
  end

  def move_to_cache
    false
  end

  private

  def size_range
    0..128.kilobytes
  end
end
