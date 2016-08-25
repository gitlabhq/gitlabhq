class CycleAnalytics
  def issue
    calculate_metric(Queries::issues,
                     -> (data_point) { data_point[:issue].created_at },
                     Queries::issue_first_associated_with_milestone_or_first_added_to_list_label_time)
  end

  def plan
    calculate_metric(Queries::issues,
                     Queries::issue_first_associated_with_milestone_or_first_added_to_list_label_time,
                     Queries::issue_closing_merge_request_opened_time)
  end

  def code
    calculate_metric(Queries::merge_requests_closing_issues,
                     -> (data_point) { data_point[:merge_request].created_at },
                     Queries::mr_wip_flag_removed_or_assigned_to_user_other_than_author_time)
  end

  def review
    calculate_metric(Queries::merge_requests_closing_issues,
                     Queries::mr_wip_flag_removed_or_assigned_to_user_other_than_author_time,
                     Queries::mr_first_closed_or_merged_at)
  end

  def staging
    calculate_metric(Queries::merge_requests_closing_issues,
                     Queries::mr_merged_at,
                     Queries::mr_deployed_to_any_environment_at)
  end

  def production
    calculate_metric(Queries::merge_requests_closing_issues,
                     -> (data_point) { data_point[:issue].created_at },
                     Queries::mr_deployed_to_production_at)
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
