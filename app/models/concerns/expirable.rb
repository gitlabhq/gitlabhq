module Expirable
  extend ActiveSupport::Concern

  included do
    scope :expired, -> { where('expires_at <= ?', Time.current) }
  end

  def expires?
    expires_at.present?
  end

  def expires_soon?
    expires_at < 7.days.from_now
  end
end
