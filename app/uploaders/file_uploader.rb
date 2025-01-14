# frozen_string_literal: true

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

  # This pattern is vulnerable to malicious inputs, so use Gitlab::UntrustedRegexp
  # to place bounds on execution time
  MARKDOWN_PATTERN = Gitlab::UntrustedRegexp.new(
    '!?\[.*?\]\(/uploads/(?P<secret>[0-9a-f]{32})/(?P<file>.*?)\)'
  )

  DYNAMIC_PATH_PATTERN = %r{.*(?<secret>\b(?:\h{10}|\h{32}))\/(?<identifier>.*)}
  VALID_SECRET_PATTERN = %r{\A\h{10,32}\z}

  InvalidSecret = Class.new(StandardError)

  after :remove, :prune_store_dir

  def self.root
    File.join(options.storage_path, 'uploads')
  end

  def self.absolute_path(upload)
    File.join(
      root,
      relative_path(upload)
    )
  end

  def self.relative_path(upload)
    File.join(
      base_dir(upload.model),
      upload.path # already contain the dynamic_segment, see #upload_path
    )
  end

  def self.base_dir(model, store = Store::LOCAL)
    decorated_model = model
    decorated_model = Storage::Hashed.new(model) if store == Store::REMOTE

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
    when Storage::Hashed then model.disk_path
    else
      model.hashed_storage?(:attachments) ? model.disk_path : model.full_path
    end
  end

  def self.generate_secret
    SecureRandom.hex
  end

  def self.extract_dynamic_path(path)
    DYNAMIC_PATH_PATTERN.match(path)
  end

  def upload_paths(identifier)
    [
      File.join(secret, identifier),
      File.join(base_dir(Store::REMOTE), secret, identifier)
    ]
  end

  attr_accessor :model

  def initialize(model, mounted_as = nil, **uploader_context)
    super(model, nil, **uploader_context)

    @model = model.is_a?(Namespaces::ProjectNamespace) ? model.project : model
    apply_context!(uploader_context)
  end

  def initialize_copy(from)
    super

    @secret = self.class.generate_secret
    @upload = nil # calling record_upload would delete the old upload if set
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
      local_storage_path(identifier)
    else
      remote_storage_path(identifier)
    end
  end

  def local_storage_path(file_identifier)
    File.join(dynamic_segment, file_identifier)
  end

  def remote_storage_path(file_identifier)
    File.join(store_dir, file_identifier)
  end

  def store_dirs
    {
      Store::LOCAL => File.join(base_dir, dynamic_segment),
      Store::REMOTE => File.join(base_dir(ObjectStorage::Store::REMOTE), dynamic_segment)
    }
  end

  def to_h
    {
      alt: markdown_name,
      url: secure_url,
      markdown: markdown_link
    }
  end

  def upload=(value)
    super

    return unless value
    return if apply_context!(value.uploader_context)

    # fallback to the regex based extraction
    if matches = self.class.extract_dynamic_path(value.path)
      @secret = matches[:secret]
      @identifier = matches[:identifier]
    end
  end

  def secret
    @secret ||= self.class.generate_secret

    raise InvalidSecret unless VALID_SECRET_PATTERN.match?(@secret)

    @secret
  end

  # return a new uploader with a file copy on another container
  def self.copy_to(uploader, to_container)
    moved = self.new(to_container)
    moved.object_store = uploader.object_store
    moved.filename = uploader.filename

    moved.copy_file(uploader.file)
    moved
  end

  def copy_file(file)
    to_path = if file_storage?
                File.join(self.class.root, store_path)
              else
                store_path
              end

    self.file = file.copy_to(to_path)
    record_upload # after_store is not triggered
  end

  private

  def apply_context!(uploader_context)
    @secret, @identifier, @uploaded_by_user_id = uploader_context.values_at(:secret, :identifier, :uploaded_by_user_id)

    !!(@secret && @identifier)
  end

  def build_upload
    super.tap do |upload|
      upload.secret = secret
      upload.uploaded_by_user_id = @uploaded_by_user_id
    end
  end

  def prune_store_dir
    storage.delete_dir!(store_dir) # only remove when empty
  end

  def identifier
    @identifier ||= filename
  end

  def dynamic_segment
    secret
  end

  def secure_url
    File.join('/uploads', @secret, filename)
  end
end
