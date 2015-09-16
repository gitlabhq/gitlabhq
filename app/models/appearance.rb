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
#  dark_logo   :string(255)
#  light_logo  :string(255)
#

class Appearance < ActiveRecord::Base
  validates :title, presence: true
  validates :description, presence: true
  validates :logo, file_size: { maximum: 1000.kilobytes.to_i }
  validates :light_logo, file_size: { maximum: 1000.kilobytes.to_i }

  mount_uploader :logo, AttachmentUploader
  mount_uploader :light_logo, AttachmentUploader
end
