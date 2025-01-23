# frozen_string_literal: true

module ServicePing
  class QueriesServicePing < ApplicationRecord
    REPORTING_CADENCE = RawUsageData::REPORTING_CADENCE

    belongs_to :organization, class_name: 'Organizations::Organization'

    attribute :payload, Gitlab::Database::Type::JsonPgSafe.new

    validates :payload, presence: true
    validates :recorded_at, presence: true, uniqueness: true

    scope :for_current_reporting_cycle, -> do
      where(created_at: REPORTING_CADENCE.ago.beginning_of_day..)
        .order(created_at: :desc)
    end
  end
end
