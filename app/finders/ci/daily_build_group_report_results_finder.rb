# frozen_string_literal: true

# DailyBuildGroupReportResultsFinder
#
# Used to filter DailyBuildGroupReportResults by set of params
#
# Arguments:
#   current_user
#   params:
#     project: integer
#     group: integer
#     coverage: boolean
#     ref_path: string
#     start_date: string
#     end_date: string
#     sort: boolean
#     limit: integer

module Ci
  class DailyBuildGroupReportResultsFinder
    include Gitlab::Allowable

    MAX_ITEMS = 1_000
    REPORT_WINDOW = 90.days
    DATE_FORMAT_ALLOWED = '%Y-%m-%d'

    attr_reader :params, :current_user

    def initialize(params: {}, current_user: nil)
      @params = params
      @current_user = current_user
    end

    def execute
      return Ci::DailyBuildGroupReportResult.none unless query_allowed?

      collection = Ci::DailyBuildGroupReportResult.by_projects(params[:project])
      filter_report_results(collection)
    end

    private

    def query_allowed?
      can?(current_user, :read_build_report_results, params[:project])
    end

    def filter_report_results(collection)
      collection = by_coverage(collection)
      collection = by_ref_path(collection)
      collection = by_dates(collection)

      collection = sort(collection)
      limit_by(collection)
    end

    def by_coverage(items)
      params[:coverage].present? ? items.with_coverage : items
    end

    def by_ref_path(items)
      params[:ref_path].present? ? items.by_ref_path(params[:ref_path]) : items.with_default_branch
    end

    def by_dates(items)
      params[:start_date].present? && params[:end_date].present? ? items.by_dates(start_date, end_date) : items
    end

    def sort(items)
      params[:sort].present? ? items.ordered_by_date_and_group_name : items
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def limit_by(items)
      items.limit(limit)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def limit
      return MAX_ITEMS unless params[:limit].present?

      [params[:limit].to_i, MAX_ITEMS].min
    end

    def start_date
      start_date = Date.strptime(params[:start_date], DATE_FORMAT_ALLOWED) rescue REPORT_WINDOW.ago.to_date

      # The start_date cannot be older than `end_date - 90 days`
      [start_date, end_date - REPORT_WINDOW].max
    end

    def end_date
      Date.strptime(params[:end_date], DATE_FORMAT_ALLOWED) rescue Date.current
    end
  end
end

Ci::DailyBuildGroupReportResultsFinder.prepend_mod_with('Ci::DailyBuildGroupReportResultsFinder')
