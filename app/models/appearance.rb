class Appearance < ActiveRecord::Base
  validates :title, presence: true
  validates :description, presence: true
  validates :logo, file_size: { maximum: 1000.kilobytes.to_i }
  validates :light_logo, file_size: { maximum: 1000.kilobytes.to_i }

  mount_uploader :logo, AttachmentUploader
  mount_uploader :light_logo, AttachmentUploader
end
