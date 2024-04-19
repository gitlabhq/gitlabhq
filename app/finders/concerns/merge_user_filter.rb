# frozen_string_literal: true

module MergeUserFilter
  private

  def by_merge_user(items)
    return items unless params.merge_user_id? || params.merge_user_username?

    mr_metrics_scope = MergeRequest::Metrics
    mr_metrics_scope = mr_metrics_scope.merged_by(params.merge_user)

    if params.merge_user
      items.join_metrics.merge(mr_metrics_scope)
    else # merge_user user not found
      items.none
    end
  end
end
