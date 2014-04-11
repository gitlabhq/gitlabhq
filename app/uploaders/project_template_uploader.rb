# encoding: utf-8

class ProjectTemplateUploader < CarrierWave::Uploader::Base

  storage :file

  def store_dir
    File.join(Gitlab.config.gitlab.templates_path, "#{model.id}", "#{model.save_name}")
  end

  def move_to_cache
    true
  end

  def move_to_store
    true
  end

  def zip?
    zip_ext = %w(zip)
    if file.respond_to?(:extension)
      zip_ext.include?(file.extension.downcase)
    else
      ext = file.path.split('.').last.downcase
      zip_ext.include?(ext)
    end
  rescue
    false
  end

end
