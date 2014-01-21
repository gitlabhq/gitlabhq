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
#  color      :string(255)
#  font       :string(255)
#

class BroadcastMessage < ActiveRecord::Base
  attr_accessible :alert_type, :color, :ends_at, :font, :message, :starts_at

  validates :message, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true

  validates :color, format: { with: /\A\#[0-9A-Fa-f]{6}+\Z/ }, allow_blank: true
  validates :font,  format: { with: /\A\#[0-9A-Fa-f]{6}+\Z/ }, allow_blank: true

  def self.current
    where("ends_at > :now AND starts_at < :now", now: Time.zone.now).last
  end
end
