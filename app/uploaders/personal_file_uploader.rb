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

<<<<<<< HEAD
  def object_store
    return Store::LOCAL unless model

    super
  end

  # Revert-Override
  def store_dir
    store_dirs[object_store]
  end

  def store_dirs
    {
      Store::LOCAL => File.join(base_dir, dynamic_segment),
      Store::REMOTE => File.join(model_path_segment, dynamic_segment)
    }
=======
  # Revert-Override
  def store_dir
    File.join(base_dir, dynamic_segment)
>>>>>>> upstream/master
  end

  private

  def secure_url
    File.join('/', base_dir, secret, file.filename)
  end
end
