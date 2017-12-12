class Upload < ActiveRecord::Base
  # Upper limit for foreground checksum processing
  CHECKSUM_THRESHOLD = 100.megabytes

  belongs_to :model, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  validates :size, presence: true
  validates :path, presence: true
  validates :model, presence: true
  validates :uploader, presence: true

  before_save  :calculate_checksum, if:     :foreground_checksum?
  after_commit :schedule_checksum,  unless: :foreground_checksum?

  def self.remove_path(path)
    where(path: path).destroy_all
  end

  def self.record(uploader)
    upload = uploader.upload || new

    binding.pry
    upload.update_attributes(
      size: uploader.file.size,
      path: uploader.dynamic_path,
      model: uploader.model,
      uploader: uploader.class.to_s,
      store: uploader.try(:object_store) || ObjectStorage::Store::LOCAL
    )
  end

  def self.hexdigest(absolute_path)
    return unless File.exist?(absolute_path)

    Digest::SHA256.file(absolute_path).hexdigest
  end

  def absolute_path
    return path unless relative_path?

    uploader_class.absolute_path(self)
  end

  def calculate_checksum
    return unless exist?

    self.checksum = self.class.hexdigest(absolute_path)
  end

  def exist?
    File.exist?(absolute_path)
  end

  def build_uploader(from = nil)
    uploader = from || uploader_class.new(model)

    uploader.upload = self
    uploader.object_store = store
    uploader
  end

  #private

  def foreground_checksum?
    size <= CHECKSUM_THRESHOLD
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
end
