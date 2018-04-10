class Upload < ActiveRecord::Base
  # Upper limit for foreground checksum processing
  CHECKSUM_THRESHOLD = 100.megabytes

  belongs_to :model, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  validates :size, presence: true
  validates :path, presence: true
  validates :model, presence: true
  validates :uploader, presence: true

  scope :with_files_stored_locally, -> { where(store: [nil, ObjectStorage::Store::LOCAL]) }

  before_save  :calculate_checksum!, if: :foreground_checksummable?
  after_commit :schedule_checksum,   if: :checksummable?

  # as the FileUploader is not mounted, the default CarrierWave ActiveRecord
  # hooks are not executed and the file will not be deleted
  after_destroy :delete_file!, if: -> { uploader_class <= FileUploader }

  def self.hexdigest(path)
    Digest::SHA256.file(path).hexdigest
  end

  def absolute_path
    raise ObjectStorage::RemoteStoreError, "Remote object has no absolute path." unless local?
    return path unless relative_path?

    uploader_class.absolute_path(self)
  end

  def calculate_checksum!
    self.checksum = nil
    return unless checksummable?

    self.checksum = Digest::SHA256.file(absolute_path).hexdigest
  end

  def build_uploader(mounted_as = nil)
    uploader_class.new(model, mounted_as || mount_point).tap do |uploader|
      uploader.upload = self
      uploader.retrieve_from_store!(identifier)
    end
  end

  def exist?
    File.exist?(absolute_path)
  end

  def uploader_context
    {
      identifier: identifier,
      secret: secret
    }.compact
  end

  def local?
    return true if store.nil?

    store == ObjectStorage::Store::LOCAL
  end

  private

  def delete_file!
    build_uploader.remove!
  end

  def checksummable?
    checksum.nil? && local? && exist?
  end

  def foreground_checksummable?
    checksummable? && size <= CHECKSUM_THRESHOLD
  end

  def schedule_checksum
    UploadChecksumWorker.perform_async(id)
  end

  def relative_path?
    !path.start_with?('/')
  end

  def uploader_class
    Object.const_get(uploader)
  end

  def identifier
    File.basename(path)
  end

  def mount_point
    super&.to_sym
  end
end
