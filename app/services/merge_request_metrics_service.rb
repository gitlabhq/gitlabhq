# frozen_string_literal: true

class MergeRequestMetricsService
  delegate :update!, to: :@merge_request_metrics

  def initialize(merge_request_metrics)
    @merge_request_metrics = merge_request_metrics
  end

  def merge(event)
    update!(merged_by_id: event.author_id, merged_at: event.created_at)
  end

  def close(event)
    update!(latest_closed_by_id: event.author_id, latest_closed_at: event.created_at)
  end

  def reopen
    update!(latest_closed_by_id: nil, latest_closed_at: nil)
  end
end

MergeRequestMetricsService.prepend_mod_with('MergeRequestMetricsService')
