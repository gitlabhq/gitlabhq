# == Schema Information
#
# Table name: broadcast_messages
#
#  id         :integer          not null, primary key
#  message    :text             default(""), not null
#  starts_at  :datetime
#  ends_at    :datetime
#  alert_type :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class BroadcastMessage < ActiveRecord::Base
  attr_accessible :alert_type, :ends_at, :message, :starts_at

  validates :message, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true

  def self.current
    where("ends_at > :now AND starts_at < :now", now: Time.zone.now).last
  end
end
