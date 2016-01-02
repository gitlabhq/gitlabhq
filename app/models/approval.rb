# == Schema Information
#
# Table name: approvals
#
#  id               :integer          not null, primary key
#  merge_request_id :integer          not null
#  user_id          :integer          not null
#  created_at       :datetime
#  updated_at       :datetime
#

class Approval < ActiveRecord::Base
  belongs_to :user
  belongs_to :merge_request

  validates :merge_request_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: [:merge_request_id] }
end
