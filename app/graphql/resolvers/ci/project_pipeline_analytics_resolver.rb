# frozen_string_literal: true

module Resolvers
  module Ci
    class ProjectPipelineAnalyticsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Ci::AnalyticsType, null: true

      authorizes_object!
      authorize :read_ci_cd_analytics
      extras [:lookahead]

      STATUS_GROUPS = %i[success failed other].freeze

      def resolve(lookahead: nil)
        weekly_stats = Gitlab::Ci::Charts::WeekChart.new(object, selected_statuses(lookahead, :week))
        monthly_stats = Gitlab::Ci::Charts::MonthChart.new(object, selected_statuses(lookahead, :month))
        yearly_stats = Gitlab::Ci::Charts::YearChart.new(object, selected_statuses(lookahead, :year))

        result = {
          week_pipelines: weekly_stats,
          month_pipelines: monthly_stats,
          year_pipelines: yearly_stats
        }

        if any_field_selected?(lookahead, :week_pipelines_labels, :week_pipelines_totals, :week_pipelines_successful)
          result.merge!(
            week_pipelines_labels: weekly_stats.labels,
            week_pipelines_totals: weekly_stats.totals(status: :all),
            week_pipelines_successful: weekly_stats.totals(status: :success))
        end

        if any_field_selected?(lookahead, :month_pipelines_labels, :month_pipelines_totals, :month_pipelines_successful)
          result.merge!(
            month_pipelines_labels: monthly_stats.labels,
            month_pipelines_totals: monthly_stats.totals(status: :all),
            month_pipelines_successful: monthly_stats.totals(status: :success))
        end

        if any_field_selected?(lookahead, :year_pipelines_labels, :year_pipelines_totals, :year_pipelines_successful)
          result.merge!(
            year_pipelines_labels: yearly_stats.labels,
            year_pipelines_totals: yearly_stats.totals(status: :all),
            year_pipelines_successful: yearly_stats.totals(status: :success))
        end

        if any_field_selected?(lookahead, :pipeline_times_labels, :pipeline_times_values)
          pipeline_times = Gitlab::Ci::Charts::PipelineTime.new(object, [])
          result.merge!(
            pipeline_times_labels: pipeline_times.labels,
            pipeline_times_values: pipeline_times.pipeline_times)
        end

        result
      end

      private

      def any_field_selected?(lookahead, *fields)
        fields.any? { |field| lookahead&.selects?(field) }
      end

      def selected_statuses(lookahead, period)
        return [] unless lookahead

        STATUS_GROUPS.filter do |status|
          lookahead.selection(:"#{period}_pipelines").selects?(:totals, arguments: { status: status })
        end
      end
    end
  end
end
