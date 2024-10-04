# frozen_string_literal: true

module Ci
  class BuildReportResult < Ci::ApplicationRecord
    include Ci::Partitionable

    self.primary_key = :build_id

    belongs_to :build,
      ->(report_result) { in_partition(report_result) },
      class_name: 'Ci::Build',
      partition_foreign_key: :partition_id,
      inverse_of: :report_results
    belongs_to :project, class_name: "Project", inverse_of: :build_report_results

    partitionable scope: :build

    validates :build, :project, presence: true
    validates :data, json_schema: { filename: "build_report_result_data" }

    store_accessor :data, :tests

    def tests_name
      tests["name"]
    end

    def tests_duration
      tests["duration"]
    end

    def tests_success
      tests["success"].to_i
    end

    def tests_failed
      tests["failed"].to_i
    end

    def tests_errored
      tests["errored"].to_i
    end

    def tests_skipped
      tests["skipped"].to_i
    end

    def suite_error
      tests["suite_error"]
    end
  end
end
