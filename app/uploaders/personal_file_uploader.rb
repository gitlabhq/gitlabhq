# frozen_string_literal: true

class PersonalFileUploader < FileUploader
  # Re-Override
  def self.root
    options.storage_path
  end

  def self.workhorse_local_upload_path
    File.join(options.storage_path, 'uploads', TMP_UPLOAD_PATH)
  end

  def self.base_dir(model, _store = nil)
    # base_dir is the path seen by the user when rendering Markdown, so
    # it should be the same for both local and object storage. It is
    # typically prefaced with uploads/-/system, but that prefix
    # is omitted in the path stored on disk.
    File.join(options.base_dir, model_path_segment(model))
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

  # A personal snippet path is stored using FileUploader#upload_path.
  #
  # The format for the path:
  #
  # Local storage: :random_hex/:filename.
  # Object storage: personal_snippet/:id/:random_hex/:filename.
  #
  # upload_paths represent the possible paths for a given identifier,
  # which will vary depending on whether the file is stored in local or
  # object storage. upload_path should match an element in upload_paths.
  #
  # base_dir represents the path seen by the user in Markdown, and it
  # should always be prefixed with uploads/-/system.
  #
  # store_dirs represent the paths that are actually used on disk. For
  # object storage, this should omit the prefix /uploads/-/system.
  #
  # For example, consider the requested path /uploads/-/system/personal_snippet/172/ff4ad5c2e40b39ae57cda51577317d20/file.png.
  #
  # For local storage:
  #
  # File on disk: /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/system/personal_snippet/172/ff4ad5c2e40b39ae57cda51577317d20/file.png.
  #
  # base_dir: uploads/-/system/personal_snippet/172
  # upload_path: ff4ad5c2e40b39ae57cda51577317d20/file.png
  # upload_paths: ["ff4ad5c2e40b39ae57cda51577317d20/file.png", "personal_snippet/172/ff4ad5c2e40b39ae57cda51577317d20/file.png"].
  # store_dirs:
  # => {1=>"uploads/-/system/personal_snippet/172/ff4ad5c2e40b39ae57cda51577317d20", 2=>"personal_snippet/172/ff4ad5c2e40b39ae57cda51577317d20"}
  #
  # For object storage:
  #
  # upload_path: personal_snippet/172/ff4ad5c2e40b39ae57cda51577317d20/file.png
  def upload_paths(identifier)
    [
      local_storage_path(identifier),
      File.join(remote_storage_base_path, identifier)
    ]
  end

  def store_dirs
    {
      Store::LOCAL => File.join(base_dir, dynamic_segment),
      Store::REMOTE => remote_storage_base_path
    }
  end

  private

  # To avoid prefacing the remote storage path with `/uploads/-/system`,
  # we just drop that part so that the destination path will be
  # personal_snippet/:id/:random_hex/:filename.
  def remote_storage_base_path
    File.join(self.class.model_path_segment(model), dynamic_segment)
  end

  def secure_url
    File.join('/', base_dir, secret, filename)
  end
end
