class Appearance < ActiveRecord::Base
  include CacheMarkdownField

  cache_markdown_field :description

  validates :title,       presence: true
  validates :description, presence: true
  validates :logo,        file_size: { maximum: 1.megabyte }
  validates :header_logo, file_size: { maximum: 1.megabyte }

  mount_uploader :logo,         AttachmentUploader
  mount_uploader :header_logo,  AttachmentUploader
  has_many :uploads, as: :model, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
end
