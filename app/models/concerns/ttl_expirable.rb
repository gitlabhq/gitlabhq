# frozen_string_literal: true

module TtlExpirable
  extend ActiveSupport::Concern

  included do
    validates :status, presence: true

    enum status: { default: 0, expired: 1, processing: 2, error: 3 }

    scope :updated_before, ->(number_of_days) { where("updated_at <= ?", Time.zone.now - number_of_days.days) }
    scope :active, -> { where(status: :default) }

    scope :lock_next_by, ->(sort) do
      order(sort)
        .limit(1)
        .lock('FOR UPDATE SKIP LOCKED')
    end
  end
end
