class CycleAnalytics
  def issue
    calculate_metric(Queries::issues,
                     -> (data_point) { data_point[:issue].created_at },
                     [Queries::issue_first_associated_with_milestone_at, Queries::issue_first_added_to_list_label_at])
  end

  def plan
    calculate_metric(Queries::issues,
                     [Queries::issue_first_associated_with_milestone_at, Queries::issue_first_added_to_list_label_at],
                     Queries::issue_closing_merge_request_opened_at)
  end

  def code
    calculate_metric(Queries::merge_requests_closing_issues,
                     -> (data_point) { data_point[:merge_request].created_at },
                     [Queries::merge_request_first_assigned_to_user_other_than_author_at, Queries::merge_request_wip_flag_first_removed_at])
  end

  def test
    calculate_metric(Queries::merge_requests_closing_issues,
                     Queries::merge_request_build_started_at,
                     Queries::merge_request_build_finished_at)
  end

  def review
    calculate_metric(Queries::merge_requests_closing_issues,
                     [Queries::merge_request_first_assigned_to_user_other_than_author_at, Queries::merge_request_wip_flag_first_removed_at],
                     [Queries::merge_request_first_closed_at, Queries::merge_request_merged_at])
  end

  def staging
    calculate_metric(Queries::merge_requests_closing_issues,
                     Queries::merge_request_merged_at,
                     Queries::merge_request_deployed_to_any_environment_at)
  end

  def production
    calculate_metric(Queries::merge_requests_closing_issues,
                     -> (data_point) { data_point[:issue].created_at },
                     Queries::merge_request_deployed_to_production_at)
  end

  private

  def calculate_metric(data, start_time_fns, end_time_fns)
    times = data.map do |data_point|
      start_time = Array.wrap(start_time_fns).map { |fn| fn[data_point] }.compact.first
      end_time = Array.wrap(end_time_fns).map { |fn| fn[data_point] }.compact.first

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
