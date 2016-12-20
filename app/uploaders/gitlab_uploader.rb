class GitlabUploader < CarrierWave::Uploader::Base
  # Reduce disk IO
  def move_to_cache
    true
  end

  # Reduce disk IO
  def move_to_store
    true
  end
end
