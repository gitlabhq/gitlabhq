# frozen_string_literal: true

class NamespaceFileUploader < FileUploader
  # Re-Override
  def self.root
    options.storage_path
  end

  def self.base_dir(model, store = nil)
    base_dirs(model)[store || Store::LOCAL]
  end

  def self.base_dirs(model)
    {
      Store::LOCAL => File.join(options.base_dir, 'namespace', model_path_segment(model)),
      Store::REMOTE => File.join('namespace', model_path_segment(model))
    }
  end

  def self.model_path_segment(model)
    File.join(model.id.to_s)
  end

  def self.workhorse_local_upload_path
    File.join(options.storage_path, 'uploads', TMP_UPLOAD_PATH)
  end

  # Re-Override
  def store_dir
    store_dirs[object_store]
  end
end
