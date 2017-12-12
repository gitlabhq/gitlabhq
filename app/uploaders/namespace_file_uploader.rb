class NamespaceFileUploader < FileUploader
  storage_options Gitlab.config.uploads

  def self.base_dir(model)
    File.join(storage_options&.base_dir, 'namespace', model_path_segment(model))
  end

  def self.model_path_segment(model)
    File.join(model.id.to_s)
  end

  # Re-Override
  def store_dir
    store_dirs[object_store]
  end

  def store_dirs
    {
      Store::LOCAL => File.join(base_dir, dynamic_segment),
      Store::REMOTE => File.join('namespace', model_path_segment, dynamic_segment)
    }
  end
end
