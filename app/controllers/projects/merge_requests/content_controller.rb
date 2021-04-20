# frozen_string_literal: true

class Projects::MergeRequests::ContentController < Projects::MergeRequests::ApplicationController
  # @merge_request.check_mergeability is not executed here since
  # widget serializer calls it via mergeable? method
  # but we might want to call @merge_request.check_mergeability
  # for other types of serialization

  before_action :close_merge_request_if_no_source_project
  before_action :set_polling_header
  around_action :allow_gitaly_ref_name_caching

  FAST_POLLING_INTERVAL = 10.seconds.in_milliseconds
  SLOW_POLLING_INTERVAL = 5.minutes.in_milliseconds

  def widget
    check_mergeability_async!

    respond_to do |format|
      format.json do
        render json: serializer(MergeRequestPollWidgetEntity)
      end
    end
  end

  def cached_widget
    respond_to do |format|
      format.json do
        render json: serializer(MergeRequestPollCachedWidgetEntity)
      end
    end
  end

  private

  def set_polling_header
    interval = merge_request.open? ? FAST_POLLING_INTERVAL : SLOW_POLLING_INTERVAL
    Gitlab::PollingInterval.set_header(response, interval: interval)
  end

  def serializer(entity)
    serializer = MergeRequestSerializer.new(current_user: current_user, project: merge_request.project)
    serializer.represent(merge_request, { async_mergeability_check: params[:async_mergeability_check] }, entity)
  end

  def check_mergeability_async!
    return unless Feature.enabled?(:check_mergeability_async_in_widget, merge_request.project, default_enabled: :yaml)
    return if params[:async_mergeability_check].blank?

    merge_request.check_mergeability(async: true)
  end
end
