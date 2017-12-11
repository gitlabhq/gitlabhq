class NamespaceFileUploader < FileUploader
  def self.base_dir
    File.join(root_dir, '-', 'system', 'namespace')
  end

  def self.dynamic_path_segment(model)
    dynamic_path_builder(model.id.to_s)
  end

  private

  def secure_url
    File.join('/uploads', @secret, file.filename)
  end
end
