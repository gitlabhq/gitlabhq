# frozen_string_literal: true

module Resolvers
  class ProjectPipelineStatisticsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    type Types::Ci::AnalyticsType, null: true

    authorizes_object!
    authorize :read_ci_cd_analytics

    def resolve
      weekly_stats = Gitlab::Ci::Charts::WeekChart.new(object)
      monthly_stats = Gitlab::Ci::Charts::MonthChart.new(object)
      yearly_stats = Gitlab::Ci::Charts::YearChart.new(object)
      pipeline_times = Gitlab::Ci::Charts::PipelineTime.new(object)

      {
        week_pipelines_labels: weekly_stats.labels,
        week_pipelines_totals: weekly_stats.total,
        week_pipelines_successful: weekly_stats.success,
        month_pipelines_labels: monthly_stats.labels,
        month_pipelines_totals: monthly_stats.total,
        month_pipelines_successful: monthly_stats.success,
        year_pipelines_labels: yearly_stats.labels,
        year_pipelines_totals: yearly_stats.total,
        year_pipelines_successful: yearly_stats.success,
        pipeline_times_labels: pipeline_times.labels,
        pipeline_times_values: pipeline_times.pipeline_times
      }
    end
  end
end
