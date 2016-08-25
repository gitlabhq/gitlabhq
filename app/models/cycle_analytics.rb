class CycleAnalytics
  def issue
    issues = Issue.includes(:metrics).where("issue_metrics.id IS NOT NULL").references(:issue_metrics).to_a
    start_time_fn = -> (issue) { issue.created_at  }
    end_time_fn = -> (issue) { issue.metrics.first_associated_with_milestone_at.presence || issue.metrics.first_added_to_board_at.presence }

    calculate_metric(issues, start_time_fn, end_time_fn)
  end

  def plan
    issues = Issue.includes(:metrics).where("issue_metrics.id IS NOT NULL").references(:issue_metrics).to_a
    start_time_fn = -> (issue) { issue.metrics.first_associated_with_milestone_at.presence || issue.metrics.first_added_to_board_at.presence }
    end_time_fn = lambda do |issue|
      merge_requests = issue.closed_by_merge_requests
      merge_requests.map(&:created_at).min if merge_requests.present?
    end

    calculate_metric(issues, start_time_fn, end_time_fn)
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
    size = coll.length
    (coll[size / 2] + coll[(size - 1) / 2]) / 2.0
  end
end
