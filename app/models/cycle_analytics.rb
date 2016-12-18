class CycleAnalytics
  STAGES = %i[issue plan code test review staging production].freeze

  def initialize(project, current_user, from:)
    @project = project
    @current_user = current_user
    @from = from
    @fetcher = Gitlab::CycleAnalytics::MetricsFetcher.new(project: project, from: from, branch: nil)
  end

  def summary
    @summary ||= Summary.new(@project, @current_user, from: @from)
  end

  def permissions(user:)
    Gitlab::CycleAnalytics::Permissions.get(user: user, project: @project)
  end

  def issue
    @fetcher.calculate_metric(:issue,
                     Issue.arel_table[:created_at],
                     [Issue::Metrics.arel_table[:first_associated_with_milestone_at],
                      Issue::Metrics.arel_table[:first_added_to_board_at]])
  end

  def plan
    @fetcher.calculate_metric(:plan,
                     [Issue::Metrics.arel_table[:first_associated_with_milestone_at],
                      Issue::Metrics.arel_table[:first_added_to_board_at]],
                     Issue::Metrics.arel_table[:first_mentioned_in_commit_at])
  end

  def code
    @fetcher.calculate_metric(:code,
                     Issue::Metrics.arel_table[:first_mentioned_in_commit_at],
                     MergeRequest.arel_table[:created_at])
  end

  def test
    @fetcher.calculate_metric(:test,
                     MergeRequest::Metrics.arel_table[:latest_build_started_at],
                     MergeRequest::Metrics.arel_table[:latest_build_finished_at])
  end

  def review
    @fetcher.calculate_metric(:review,
                     MergeRequest.arel_table[:created_at],
                     MergeRequest::Metrics.arel_table[:merged_at])
  end

  def staging
    @fetcher.calculate_metric(:staging,
                     MergeRequest::Metrics.arel_table[:merged_at],
                     MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
  end

  def production
    @fetcher.calculate_metric(:production,
                     Issue.arel_table[:created_at],
                     MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
  end
end
