# frozen_string_literal: true

module TtlExpirable
  extend ActiveSupport::Concern

  included do
    attribute :read_at, default: -> { Time.zone.now }
    validates :status, presence: true

    enum status: { default: 0, pending_destruction: 1, processing: 2, error: 3 }

    scope :read_before, ->(number_of_days) { where("read_at <= ?", Time.zone.now - number_of_days.days) }
    scope :active, -> { where(status: :default) }
  end

  def read!
    self.update(read_at: Time.zone.now)
  end
end
