class PersonalFileUploader < FileUploader
  # Re-Override
  def self.root
    options.storage_path
  end

  def self.base_dir(model)
    File.join(options.base_dir, model_path_segment(model))
  end

  def self.model_path_segment(model)
    return 'temp/' unless model

    File.join(model.class.to_s.underscore, model.id.to_s)
  end

  # Revert-Override
  def store_dir
    File.join(base_dir, dynamic_segment)
  end

  private

  def secure_url
    File.join('/', base_dir, secret, file.filename)
  end
end
