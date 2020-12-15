# frozen_string_literal: true

class RawUsageData < ApplicationRecord
  validates :payload, presence: true
  validates :recorded_at, presence: true, uniqueness: true

  def update_sent_at!
    self.update_column(:sent_at, Time.current)
  end
end
