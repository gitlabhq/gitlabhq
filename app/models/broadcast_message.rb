# == Schema Information
#
# Table name: broadcast_messages
#
#  id         :integer          not null, primary key
#  message    :text             not null
#  starts_at  :datetime
#  ends_at    :datetime
#  created_at :datetime
#  updated_at :datetime
#  color      :string(255)
#  font       :string(255)
#

class BroadcastMessage < ActiveRecord::Base
  include Sortable

  validates :message,   presence: true
  validates :starts_at, presence: true
  validates :ends_at,   presence: true

  validates :color, allow_blank: true, color: true
  validates :font,  allow_blank: true, color: true

  default_value_for :color, '#E75E40'
  default_value_for :font,  '#FFFFFF'

  def self.current
    Rails.cache.fetch("broadcast_message_current", expires_in: 1.minute) do
      where("ends_at > :now AND starts_at <= :now", now: Time.zone.now).last
    end
  end

  def active?
    started? && !ended?
  end

  def started?
    Time.zone.now >= starts_at
  end

  def ended?
    ends_at < Time.zone.now
  end
end
