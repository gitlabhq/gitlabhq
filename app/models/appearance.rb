class Appearance < ActiveRecord::Base
  validates :title, presence: true
  validates :description, presence: true
  validates :logo, file_size: { maximum: 1000.kilobytes.to_i }

  mount_uploader :logo, AttachmentUploader
end
