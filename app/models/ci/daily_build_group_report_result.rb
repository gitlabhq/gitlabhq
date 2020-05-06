# frozen_string_literal: true

module Ci
  class DailyBuildGroupReportResult < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :last_pipeline, class_name: 'Ci::Pipeline', foreign_key: :last_pipeline_id
    belongs_to :project

    def self.upsert_reports(data)
      upsert_all(data, unique_by: :index_daily_build_group_report_results_unique_columns) if data.any?
    end
  end
end
