# == Schema Information
#
# Table name: label_links
#
#  id          :integer          not null, primary key
#  label_id    :integer
#  target_id   :integer
#  target_type :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class LabelLink < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :label

  validates :target, presence: true
  validates :label, presence: true
end
