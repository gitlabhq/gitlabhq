# frozen_string_literal: true

class RawUsageData < ApplicationRecord
  validates :payload, presence: true
  validates :recorded_at, presence: true, uniqueness: true

  def update_version_metadata!(usage_data_id:)
    self.update_columns(sent_at: Time.current, version_usage_data_id_value: usage_data_id)
  end
end
