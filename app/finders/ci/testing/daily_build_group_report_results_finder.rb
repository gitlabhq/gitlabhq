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
#     start_date: date
#     end_date: date
#     sort: boolean
#     limit: integer

module Ci
  module Testing
    class DailyBuildGroupReportResultsFinder
      include Gitlab::Allowable

      MAX_ITEMS = 1_000

      attr_reader :params, :current_user

      def initialize(params: {}, current_user: nil)
        @params = params
        @current_user = current_user
      end

      def execute
        return Ci::DailyBuildGroupReportResult.none unless query_allowed?

        collection = Ci::DailyBuildGroupReportResult.by_projects(params[:project])
        collection = filter_report_results(collection)
        collection
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
        collection = limit_by(collection)
        collection
      end

      def by_coverage(items)
        params[:coverage].present? ? items.with_coverage : items
      end

      def by_ref_path(items)
        params[:ref_path].present? ? items.by_ref_path(params[:ref_path]) : items.with_default_branch
      end

      def by_dates(items)
        params[:start_date].present? && params[:end_date].present? ? items.by_dates(params[:start_date], params[:end_date]) : items
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
    end
  end
end

Ci::Testing::DailyBuildGroupReportResultsFinder.prepend_if_ee('::EE::Ci::Testing::DailyBuildGroupReportResultsFinder')
