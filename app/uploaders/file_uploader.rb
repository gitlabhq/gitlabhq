# This class breaks the actual CarrierWave concept.
# Every uploader should use a base_dir that is model agnostic so we can build
# back URLs from base_dir-relative paths saved in the `Upload` model.
#
# As the `.base_dir` is model dependent and **not** saved in the upload model (see #upload_path)
# there is no way to build back the correct file path without the model, which defies
# CarrierWave way of storing files.
#
class FileUploader < GitlabUploader
  include UploaderHelper
  include RecordsUploads::Concern
  include ObjectStorage::Concern
  prepend ObjectStorage::Extension::RecordsUploads

  MARKDOWN_PATTERN = %r{\!?\[.*?\]\(/uploads/(?<secret>[0-9a-f]{32})/(?<file>.*?)\)}
  DYNAMIC_PATH_PATTERN = %r{(?<secret>\h{32})/(?<identifier>.*)}

  after :remove, :prune_store_dir

  # FileUploader do not run in a model transaction, so we can simply
  # enqueue a job after the :store hook.
  after :store, :schedule_background_upload

  def self.root
    File.join(options.storage_path, 'uploads')
  end

  def self.absolute_path(upload)
    File.join(
      absolute_base_dir(upload.model),
      upload.path # already contain the dynamic_segment, see #upload_path
    )
  end

  def self.base_dir(model, store = Store::LOCAL)
    decorated_model = model
    decorated_model = Storage::HashedProject.new(model) if store == Store::REMOTE

    model_path_segment(decorated_model)
  end

  # used in migrations and import/exports
  def self.absolute_base_dir(model)
    File.join(root, base_dir(model))
  end

  # Returns the part of `store_dir` that can change based on the model's current
  # path
  #
  # This is used to build Upload paths dynamically based on the model's current
  # namespace and path, allowing us to ignore renames or transfers.
  #
  # model - Object that responds to `full_path` and `disk_path`
  #
  # Returns a String without a trailing slash
  def self.model_path_segment(model)
    case model
    when Storage::HashedProject then model.disk_path
    else
      model.hashed_storage?(:attachments) ? model.disk_path : model.full_path
    end
  end

  def self.generate_secret
    SecureRandom.hex
  end

  def upload_paths(filename)
    [
      File.join(secret, filename),
      File.join(base_dir(Store::REMOTE), secret, filename)
    ]
  end

  attr_accessor :model

  def initialize(model, mounted_as = nil, **uploader_context)
    super(model, nil, **uploader_context)

    @model = model
    apply_context!(uploader_context)
  end

  # enforce the usage of Hashed storage when storing to
  # remote store as the FileMover doesn't support OS
  def base_dir(store = nil)
    self.class.base_dir(@model, store || object_store)
  end

  # we don't need to know the actual path, an uploader instance should be
  # able to yield the file content on demand, so we should build the digest
  def absolute_path
    self.class.absolute_path(@upload)
  end

  def upload_path
    if file_storage?
      # Legacy path relative to project.full_path
      File.join(dynamic_segment, identifier)
    else
      File.join(store_dir, identifier)
    end
  end

  def store_dirs
    {
      Store::LOCAL => File.join(base_dir, dynamic_segment),
      Store::REMOTE => File.join(base_dir(ObjectStorage::Store::REMOTE), dynamic_segment)
    }
  end

  def markdown_link
    markdown = "[#{markdown_name}](#{secure_url})"
    markdown.prepend("!") if image_or_video? || dangerous?
    markdown
  end

  def to_h
    {
      alt:      markdown_name,
      url:      secure_url,
      markdown: markdown_link
    }
  end

  def filename
    self.file.filename
  end

  def upload=(value)
    super

    return unless value
    return if apply_context!(value.uploader_context)

    # fallback to the regex based extraction
    if matches = DYNAMIC_PATH_PATTERN.match(value.path)
      @secret = matches[:secret]
      @identifier = matches[:identifier]
    end
  end

  def secret
    @secret ||= self.class.generate_secret
  end

  private

  def apply_context!(uploader_context)
    @secret, @identifier = uploader_context.values_at(:secret, :identifier)

    !!(@secret && @identifier)
  end

  def build_upload
    super.tap do |upload|
      upload.secret = secret
    end
  end

  def prune_store_dir
    storage.delete_dir!(store_dir) # only remove when empty
  end

  def markdown_name
    (image_or_video? ? File.basename(filename, File.extname(filename)) : filename).gsub("]", "\\]")
  end

  def identifier
    @identifier ||= filename
  end

  def dynamic_segment
    secret
  end

  def secure_url
    File.join('/uploads', @secret, file.filename)
  end
end
