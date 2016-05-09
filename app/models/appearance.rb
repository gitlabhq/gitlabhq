class Appearance < ActiveRecord::Base
  validates :title,       presence: true
  validates :description, presence: true
  validates :logo,        file_size: { maximum: 1.megabyte }
  validates :header_logo, file_size: { maximum: 1.megabyte }

  mount_uploader :logo,         AttachmentUploader
  mount_uploader :header_logo,  AttachmentUploader
end
