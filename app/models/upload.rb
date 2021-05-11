# frozen_string_literal: true

class Upload < ApplicationRecord
  include Checksummable
  # Upper limit for foreground checksum processing
  CHECKSUM_THRESHOLD = 100.megabytes

  belongs_to :model, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  validates :size, presence: true
  validates :path, presence: true
  validates :model, presence: true
  validates :uploader, presence: true

  scope :with_files_stored_locally, -> { where(store: ObjectStorage::Store::LOCAL) }
  scope :with_files_stored_remotely, -> { where(store: ObjectStorage::Store::REMOTE) }

  before_save  :calculate_checksum!, if: :foreground_checksummable?
  after_commit :schedule_checksum,   if: :needs_checksum?

  # as the FileUploader is not mounted, the default CarrierWave ActiveRecord
  # hooks are not executed and the file will not be deleted
  after_destroy :delete_file!, if: -> { uploader_class <= FileUploader }

  class << self
    def inner_join_local_uploads_projects
      upload_table = Upload.arel_table
      project_table = Project.arel_table

      join_statement = upload_table.project(upload_table[Arel.star])
                         .join(project_table)
                         .on(
                           upload_table[:model_type].eq('Project')
                             .and(upload_table[:model_id].eq(project_table[:id]))
                             .and(upload_table[:store].eq(ObjectStorage::Store::LOCAL))
                         )

      joins(join_statement.join_sources)
    end

    ##
    # FastDestroyAll concerns
    def begin_fast_destroy
      {
        Uploads::Local => Uploads::Local.new.keys(with_files_stored_locally),
        Uploads::Fog => Uploads::Fog.new.keys(with_files_stored_remotely)
      }
    end

    ##
    # FastDestroyAll concerns
    def finalize_fast_destroy(keys)
      keys.each do |store_class, paths|
        store_class.new.delete_keys_async(paths)
      end
    end
  end

  def absolute_path
    raise ObjectStorage::RemoteStoreError, _("Remote object has no absolute path.") unless local?
    return path unless relative_path?

    uploader_class.absolute_path(self)
  end

  def calculate_checksum!
    self.checksum = nil
    return unless needs_checksum?

    self.checksum = self.class.hexdigest(absolute_path)
  end

  # Initialize the associated Uploader class with current model
  #
  # @param [String] mounted_as
  # @return [GitlabUploader] one of the subclasses, defined at the model's uploader attribute
  def build_uploader(mounted_as = nil)
    uploader_class.new(model, mounted_as || mount_point).tap do |uploader|
      uploader.upload = self
    end
  end

  # Initialize the associated Uploader class with current model and
  # retrieve existing file from the store to a local cache
  #
  # @param [String] mounted_as
  # @return [GitlabUploader] one of the subclasses, defined at the model's uploader attribute
  def retrieve_uploader(mounted_as = nil)
    build_uploader(mounted_as).tap do |uploader|
      uploader.retrieve_from_store!(identifier)
    end
  end

  # This checks for existence of the upload on storage
  #
  # @return [Boolean] whether upload exists on storage
  def exist?
    exist = if local?
              File.exist?(absolute_path)
            else
              retrieve_uploader.exists?
            end

    # Help sysadmins find missing upload files
    if persisted? && !exist
      exception = RuntimeError.new("Uploaded file does not exist")
      Gitlab::ErrorTracking.track_exception(exception, self.attributes)
      Gitlab::Metrics.counter(:upload_file_does_not_exist_total, _('The number of times an upload record could not find its file')).increment
    end

    exist
  end

  def uploader_context
    {
      identifier: identifier,
      secret: secret
    }.compact
  end

  def local?
    store == ObjectStorage::Store::LOCAL
  end

  # Returns whether generating checksum is needed
  #
  # This takes into account whether file exists, if any checksum exists
  # or if the storage has checksum generation code implemented
  #
  # @return [Boolean] whether generating a checksum is needed
  def needs_checksum?
    checksum.nil? && local? && exist?
  end

  private

  def delete_file!
    retrieve_uploader.remove!
  end

  def foreground_checksummable?
    needs_checksum? && size <= CHECKSUM_THRESHOLD
  end

  def schedule_checksum
    UploadChecksumWorker.perform_async(id)
  end

  def relative_path?
    !path.start_with?('/')
  end

  def uploader_class
    Object.const_get(uploader, false)
  end

  def identifier
    File.basename(path)
  end

  def mount_point
    super&.to_sym
  end
end

Upload.prepend_mod_with('Upload')
