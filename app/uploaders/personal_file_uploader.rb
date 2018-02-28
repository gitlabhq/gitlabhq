class PersonalFileUploader < FileUploader
  def self.dynamic_path_segment(model)
    File.join(CarrierWave.root, model_path(model))
  end

  def self.base_dir
    File.join(root_dir, '-', 'system')
  end

  private

  def secure_url
    File.join(self.class.model_path(model), secret, file.filename)
  end

  def self.model_path(model)
    if model
      File.join("/#{base_dir}", model.class.to_s.underscore, model.id.to_s)
    else
      File.join("/#{base_dir}", 'temp')
    end
  end
end
