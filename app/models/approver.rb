# == Schema Information
#
# Table name: approvers
#
#  id          :integer          not null, primary key
#  target_id   :integer          not null
#  target_type :string(255)
#  user_id     :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#

class Approver < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :user

  validates :user, presence: true
end
