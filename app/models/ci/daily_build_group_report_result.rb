# frozen_string_literal: true

module Ci
  class DailyBuildGroupReportResult < Ci::ApplicationRecord
    PARAM_TYPES = %w[coverage].freeze

    belongs_to :last_pipeline, class_name: 'Ci::Pipeline', foreign_key: :last_pipeline_id
    belongs_to :project
    belongs_to :group

    validates :data, json_schema: { filename: "daily_build_group_report_result_data" }

    scope :by_ref_path, -> (ref_path) { where(ref_path: ref_path) }
    scope :by_projects, -> (ids) { where(project_id: ids) }
    scope :by_group, -> (group_id) { where(group_id: group_id) }
    scope :with_coverage, -> { where("(data->'coverage') IS NOT NULL") }
    scope :with_default_branch, -> { where(default_branch: true) }
    scope :by_dates, -> (start_date, end_date) { where(date: start_date..end_date) }
    scope :ordered_by_date_and_group_name, -> { order(date: :desc, group_name: :asc) }

    store_accessor :data, :coverage

    class << self
      def upsert_reports(data)
        upsert_all(data, unique_by: :index_daily_build_group_report_results_unique_columns) if data.any?
      end
    end
  end
end

Ci::DailyBuildGroupReportResult.prepend_mod_with('Ci::DailyBuildGroupReportResult')
