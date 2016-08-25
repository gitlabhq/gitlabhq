class CycleAnalytics
  def issue
    issues = Issue.includes(:metrics).where("issue_metrics.id IS NOT NULL").references(:issue_metrics).to_a
    start_time_fn = -> (issue) { issue.created_at  }
    calculate_metric(issues, start_time_fn, Queries::issue_first_associated_with_milestone_or_first_added_to_list_label_time)
  end

  def plan
    issues = Issue.includes(:metrics).where("issue_metrics.id IS NOT NULL").references(:issue_metrics).to_a
    calculate_metric(issues,
                     Queries::issue_first_associated_with_milestone_or_first_added_to_list_label_time,
                     Queries::issue_closing_merge_request_opened_time)
  end

  def code
    issues = Issue.all.to_a
    start_time_fn = -> (merge_request) { merge_request.created_at }
    calculate_metric(issues.map(&:closed_by_merge_requests).flatten,
                     start_time_fn,
                     Queries::mr_wip_flag_removed_or_assigned_to_user_other_than_author_time)
  end

  private

  def calculate_metric(data, start_time_fn, end_time_fn)
    times = data.map do |data_point|
      start_time = start_time_fn[data_point]
      end_time = end_time_fn[data_point]

      if start_time.present? && end_time.present?
        end_time - start_time
      end
    end

    median(times.compact)
  end

  def median(coll)
    return if coll.empty?
    size = coll.length
    (coll[size / 2] + coll[(size - 1) / 2]) / 2.0
  end
end
