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

    self.checksum = self.class.hexdigest(absolute_path)
  end

  def build_uploader
    uploader_class.new(model).tap do |uploader|
      uploader.upload = self
      uploader.retrieve_from_store!(identifier)
    end
  end

  def exist?
    File.exist?(absolute_path)
  end

  private

  def checksummable?
    checksum.nil? && local? && exist?
  end

  def local?
    return true if store.nil?

    store == ObjectStorage::Store::LOCAL
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

  def identifier
    File.basename(path)
  end

  def uploader_class
    Object.const_get(uploader)
  end
end
