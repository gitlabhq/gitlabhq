# frozen_string_literal: true

module MergedAtFilter
  private

  def by_merged_at(items)
    return items unless merged_after || merged_before

    mr_metrics_scope = MergeRequest::Metrics
    mr_metrics_scope = mr_metrics_scope.merged_after(merged_after) if merged_after.present?
    mr_metrics_scope = mr_metrics_scope.merged_before(merged_before) if merged_before.present?

    join_metrics(items, mr_metrics_scope)
  end

  def merged_after
    params[:merged_after]
  end

  def merged_before
    params[:merged_before]
  end

  # rubocop: disable CodeReuse/ActiveRecord
  #
  # This join optimizes merged_at queries when the finder is invoked for a project by moving
  # the target_project_id condition from merge_requests table to merge_request_metrics table.
  def join_metrics(items, mr_metrics_scope)
    scope = if project_id = items.where_values_hash["target_project_id"]
              # removing the original merge_requests.target_project_id condition
              items = items.unscope(where: :target_project_id)
              # adding the target_project_id condition to merge_request_metrics
              items.join_metrics(project_id)
            else
              items.join_metrics
            end

    scope.merge(mr_metrics_scope)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
