class CycleAnalytics
  include Gitlab::CycleAnalytics::MetricsFetcher

  def initialize(project, from:)
    @project = project
    @from = from
  end

  def summary
    @summary ||= Summary.new(@project, from: @from)
  end

  def issue
    calculate_metric(:issue,
                     Issue.arel_table[:created_at],
                     [Issue::Metrics.arel_table[:first_associated_with_milestone_at],
                      Issue::Metrics.arel_table[:first_added_to_board_at]])
  end

  def plan
    calculate_metric(:plan,
                     [Issue::Metrics.arel_table[:first_associated_with_milestone_at],
                      Issue::Metrics.arel_table[:first_added_to_board_at]],
                     Issue::Metrics.arel_table[:first_mentioned_in_commit_at])
  end

  def code
    calculate_metric(:code,
                     Issue::Metrics.arel_table[:first_mentioned_in_commit_at],
                     MergeRequest.arel_table[:created_at])
  end

  def test
    calculate_metric(:test,
                     MergeRequest::Metrics.arel_table[:latest_build_started_at],
                     MergeRequest::Metrics.arel_table[:latest_build_finished_at])
  end

  def review
    calculate_metric(:review,
                     MergeRequest.arel_table[:created_at],
                     MergeRequest::Metrics.arel_table[:merged_at])
  end

  def staging
    calculate_metric(:staging,
                     MergeRequest::Metrics.arel_table[:merged_at],
                     MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
  end

  def production
    calculate_metric(:production,
                     Issue.arel_table[:created_at],
                     MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
  end
end
