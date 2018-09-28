# frozen_string_literal: true

module Expirable
  extend ActiveSupport::Concern

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
    expires? && expires_at < 7.days.from_now
  end
end
