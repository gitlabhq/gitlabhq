# frozen_string_literal: true

module MergedAtFilter
  private

  # rubocop: disable CodeReuse/ActiveRecord
  def by_merged_at(items)
    return items unless merged_after || merged_before

    mr_metrics_scope = MergeRequest::Metrics
    mr_metrics_scope = mr_metrics_scope.merged_after(merged_after) if merged_after.present?
    mr_metrics_scope = mr_metrics_scope.merged_before(merged_before) if merged_before.present?

    items.joins(:metrics).merge(mr_metrics_scope)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def merged_after
    params[:merged_after]
  end

  def merged_before
    params[:merged_before]
  end
end
