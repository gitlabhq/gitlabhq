class BroadcastMessage < ActiveRecord::Base
  attr_accessible :alert_type, :ends_at, :message, :starts_at

  validates :message, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true

  def self.current
    where("ends_at > :now AND starts_at < :now", now: Time.zone.now).last
  end
end
