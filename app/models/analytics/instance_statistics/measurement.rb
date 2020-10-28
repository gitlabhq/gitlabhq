# frozen_string_literal: true

module Analytics
  module InstanceStatistics
    class Measurement < ApplicationRecord
      EXPERIMENTAL_IDENTIFIERS = %i[pipelines_succeeded pipelines_failed pipelines_canceled pipelines_skipped].freeze

      enum identifier: {
        projects: 1,
        users: 2,
        issues: 3,
        merge_requests: 4,
        groups: 5,
        pipelines: 6,
        pipelines_succeeded: 7,
        pipelines_failed: 8,
        pipelines_canceled: 9,
        pipelines_skipped: 10
      }

      IDENTIFIER_QUERY_MAPPING = {
        identifiers[:projects] => -> { Project },
        identifiers[:users] => -> { User },
        identifiers[:issues] => -> { Issue },
        identifiers[:merge_requests] => -> { MergeRequest },
        identifiers[:groups] => -> { Group },
        identifiers[:pipelines] => -> { Ci::Pipeline },
        identifiers[:pipelines_succeeded] => -> { Ci::Pipeline.success },
        identifiers[:pipelines_failed] => -> { Ci::Pipeline.failed },
        identifiers[:pipelines_canceled] => -> { Ci::Pipeline.canceled },
        identifiers[:pipelines_skipped] => -> { Ci::Pipeline.skipped }
      }.freeze

      validates :recorded_at, :identifier, :count, presence: true
      validates :recorded_at, uniqueness: { scope: :identifier }

      scope :order_by_latest, -> { order(recorded_at: :desc) }
      scope :with_identifier, -> (identifier) { where(identifier: identifier) }

      def self.measurement_identifier_values
        identifiers.values
      end
    end
  end
end
