# frozen_string_literal: true

module Expirable
  extend ActiveSupport::Concern

  DAYS_TO_EXPIRE = 7

  included do
    scope :expired, -> { where('expires_at <= ?', Time.current) }
  end

  def expired?
    expires? && expires_at <= Time.current
  end

  def expires?
    expires_at.present?
  end

  def expires_soon?
    expires? && expires_at < DAYS_TO_EXPIRE.days.from_now
  end
end
