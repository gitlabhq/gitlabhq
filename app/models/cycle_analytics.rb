class CycleAnalytics
  attr_reader :from

  def initialize(project, from:)
    @project = project
    @from = from
  end

  def as_json(options = {})
    {
      issue: issue, plan: plan, code: code, test: test,
      review: review, staging: staging, production: production
    }
  end

  def issue
    calculate_metric(Queries::issues(@project, created_after: @from),
                     -> (data_point) { data_point[:issue].created_at },
                     [Queries::issue_first_associated_with_milestone_at, Queries::issue_first_added_to_list_label_at])
  end

  def plan
    calculate_metric(Queries::issues(@project, created_after: @from),
                     [Queries::issue_first_associated_with_milestone_at, Queries::issue_first_added_to_list_label_at],
                     Queries::issue_first_mentioned_in_commit_at)
  end

  def code
    calculate_metric(Queries::merge_requests_closing_issues(@project, created_after: @from),
                     Queries::issue_first_mentioned_in_commit_at,
                     -> (data_point) { data_point[:merge_request].created_at })
  end

  def test
    calculate_metric(Queries::merge_requests_closing_issues(@project, created_after: @from),
                     Queries::merge_request_build_started_at,
                     Queries::merge_request_build_finished_at)
  end

  def review
    calculate_metric(Queries::merge_requests_closing_issues(@project, created_after: @from),
                     -> (data_point) { data_point[:merge_request].created_at },
                     Queries::merge_request_merged_at)
  end

  def staging
    calculate_metric(Queries::merge_requests_closing_issues(@project, created_after: @from),
                     Queries::merge_request_merged_at,
                     Queries::merge_request_deployed_to_production_at)
  end

  def production
    calculate_metric(Queries::merge_requests_closing_issues(@project, created_after: @from),
                     -> (data_point) { data_point[:issue].created_at },
                     Queries::merge_request_deployed_to_production_at)
  end

  private

  def calculate_metric(data, start_time_fns, end_time_fns)
    times = data.map do |data_point|
      start_time = Array.wrap(start_time_fns).map { |fn| fn[data_point] }.compact.first
      end_time = Array.wrap(end_time_fns).map { |fn| fn[data_point] }.compact.first

      if start_time.present? && end_time.present? && end_time >= start_time
        end_time - start_time
      end
    end

    median(times.compact.sort)
  end

  def median(coll)
    return if coll.empty?
    size = coll.length
    (coll[size / 2] + coll[(size - 1) / 2]) / 2.0
  end
end
