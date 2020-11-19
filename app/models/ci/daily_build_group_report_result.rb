# frozen_string_literal: true

module Ci
  class DailyBuildGroupReportResult < ApplicationRecord
    extend Gitlab::Ci::Model

    REPORT_WINDOW = 90.days
    PARAM_TYPES = %w[coverage].freeze

    belongs_to :last_pipeline, class_name: 'Ci::Pipeline', foreign_key: :last_pipeline_id
    belongs_to :project

    validates :data, json_schema: { filename: "daily_build_group_report_result_data" }

    scope :with_included_projects, -> { includes(:project) }
    scope :by_projects, -> (ids) { where(project_id: ids) }
    scope :with_coverage, -> { where("(data->'coverage') IS NOT NULL") }
    scope :with_default_branch, -> { where(default_branch: true) }
    scope :by_date, -> (start_date) { where(date: report_window(start_date)..Date.current) }

    store_accessor :data, :coverage

    class << self
      def upsert_reports(data)
        upsert_all(data, unique_by: :index_daily_build_group_report_results_unique_columns) if data.any?
      end

      def recent_results(attrs, limit: nil)
        where(attrs).order(date: :desc, group_name: :asc).limit(limit)
      end

      def report_window(start_date)
        default_date = REPORT_WINDOW.ago.to_date
        date = Date.parse(start_date) rescue default_date

        [date, default_date].max
      end
    end
  end
end

Ci::DailyBuildGroupReportResult.prepend_if_ee('EE::Ci::DailyBuildGroupReportResult')
