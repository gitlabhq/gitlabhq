class NamespaceFileUploader < FileUploader
  # Re-Override
  def self.root
    options.storage_path
  end

  def self.base_dir(model, _store = nil)
    File.join(options.base_dir, 'namespace', model_path_segment(model))
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
      Store::REMOTE => File.join('namespace', self.class.model_path_segment(model), dynamic_segment)
    }
  end
end
