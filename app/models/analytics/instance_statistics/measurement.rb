# frozen_string_literal: true

module Analytics
  module InstanceStatistics
    class Measurement < ApplicationRecord
      enum identifier: {
        projects: 1,
        users: 2,
        issues: 3,
        merge_requests: 4,
        groups: 5,
        pipelines: 6
      }

      validates :recorded_at, :identifier, :count, presence: true
      validates :recorded_at, uniqueness: { scope: :identifier }

      scope :order_by_latest, -> { order(recorded_at: :desc) }
      scope :with_identifier, -> (identifier) { where(identifier: identifier) }
    end
  end
end
