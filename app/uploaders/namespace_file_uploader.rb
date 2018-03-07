class NamespaceFileUploader < FileUploader
  # Re-Override
  def self.root
    options.storage_path
  end

  def self.base_dir(model)
    File.join(options.base_dir, 'namespace', model_path_segment(model))
  end

  def self.model_path_segment(model)
    File.join(model.id.to_s)
  end

  # Re-Override
  def store_dir
    File.join(base_dir, dynamic_segment)
  end
end
