# == Schema Information
#
# Table name: appearances
#
#  id          :integer          not null, primary key
#  title       :string(255)
#  description :text
#  logo        :string(255)
#  updated_by  :integer
#  created_at  :datetime
#  updated_at  :datetime
#  header_logo  :string(255)
#

class Appearance < ActiveRecord::Base
  validates :title,       presence: true
  validates :description, presence: true
  validates :logo,        file_size: { maximum: 1.megabyte }
  validates :header_logo, file_size: { maximum: 1.megabyte }

  mount_uploader :logo,         AttachmentUploader
  mount_uploader :header_logo,  AttachmentUploader
end
