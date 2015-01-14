class Appearance < ActiveRecord::Base
  validates :title, presence: true
  validates :description, presence: true
  validates :logo, file_size: { maximum: 1000.kilobytes.to_i }
  validates :dark_logo, file_size: { maximum: 1000.kilobytes.to_i },
            presence: true, if: :light_logo?
  validates :light_logo, file_size: { maximum: 1000.kilobytes.to_i },
            presence: true, if: :dark_logo?

  mount_uploader :logo, AttachmentUploader
  mount_uploader :dark_logo, AttachmentUploader
  mount_uploader :light_logo, AttachmentUploader

  def header_logos?
    dark_logo? && light_logo?
  end
end
