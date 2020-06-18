# frozen_string_literal: true

module Ci
  class DailyBuildGroupReportResult < ApplicationRecord
    extend Gitlab::Ci::Model

    PARAM_TYPES = %w[coverage].freeze

    belongs_to :last_pipeline, class_name: 'Ci::Pipeline', foreign_key: :last_pipeline_id
    belongs_to :project

    validates :data, json_schema: { filename: "daily_build_group_report_result_data" }

    def self.upsert_reports(data)
      upsert_all(data, unique_by: :index_daily_build_group_report_results_unique_columns) if data.any?
    end

    def self.recent_results(attrs, limit: nil)
      where(attrs).order(date: :desc, group_name: :asc).limit(limit)
    end
  end
end
