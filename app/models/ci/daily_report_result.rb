# frozen_string_literal: true

module Ci
  class DailyReportResult < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :last_pipeline, class_name: 'Ci::Pipeline', foreign_key: :last_pipeline_id
    belongs_to :project

    # TODO: Refactor this out when BuildReportResult is implemented.
    # They both need to share the same enum values for param.
    REPORT_PARAMS = {
      coverage: 0
    }.freeze

    enum param_type: REPORT_PARAMS

    def self.upsert_reports(data)
      upsert_all(data, unique_by: :index_daily_report_results_unique_columns) if data.any?
    end
  end
end
