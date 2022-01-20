# frozen_string_literal: true

module TtlExpirable
  extend ActiveSupport::Concern

  included do
    validates :status, presence: true
    default_value_for :read_at, Time.zone.now

    enum status: { default: 0, pending_destruction: 1, processing: 2, error: 3 }

    scope :read_before, ->(number_of_days) { where("read_at <= ?", Time.zone.now - number_of_days.days) }
    scope :active, -> { where(status: :default) }
  end

  def read!
    self.update(read_at: Time.zone.now)
  end
end
