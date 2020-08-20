# frozen_string_literal: true

module MergedAtFilter
  private

  # rubocop: disable CodeReuse/ActiveRecord
  def by_merged_at(items)
    return items unless merged_after || merged_before

    mr_metrics_scope = MergeRequest::Metrics
    mr_metrics_scope = mr_metrics_scope.merged_after(merged_after) if merged_after.present?
    mr_metrics_scope = mr_metrics_scope.merged_before(merged_before) if merged_before.present?

    scope = items.joins(:metrics).merge(mr_metrics_scope)
    scope = target_project_id_filter_on_metrics(scope) if Feature.enabled?(:improved_mr_merged_at_queries)
    scope
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def merged_after
    params[:merged_after]
  end

  def merged_before
    params[:merged_before]
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def target_project_id_filter_on_metrics(scope)
    scope.where(MergeRequest.arel_table[:target_project_id].eq(MergeRequest::Metrics.arel_table[:target_project_id]))
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
