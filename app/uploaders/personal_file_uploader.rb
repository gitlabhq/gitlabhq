# frozen_string_literal: true

class PersonalFileUploader < FileUploader
  # Re-Override
  def self.root
    options.storage_path
  end

  def self.base_dir(model, store = nil)
    base_dirs(model)[store || Store::LOCAL]
  end

  def self.base_dirs(model)
    {
      Store::LOCAL => File.join(options.base_dir, model_path_segment(model)),
      Store::REMOTE => model_path_segment(model)
    }
  end

  def self.model_path_segment(model)
    return 'temp/' unless model

    File.join(model.class.underscore, model.id.to_s)
  end

  def object_store
    return Store::LOCAL unless model

    super
  end

  # model_path_segment does not require a model to be passed, so we can always
  # generate a path, even when there's no model.
  def model_valid?
    true
  end

  # Revert-Override
  def store_dir
    store_dirs[object_store]
  end

  private

  def secure_url
    File.join('/', base_dir, secret, file.filename)
  end
end
