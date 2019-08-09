# frozen_string_literal: true

class Projects::MergeRequests::ContentController < Projects::MergeRequests::ApplicationController
  # @merge_request.check_mergeability is not executed here since
  # widget serializer calls it via mergeable? method
  # but we might want to call @merge_request.check_mergeability
  # for other types of serialization

  before_action :close_merge_request_if_no_source_project
  before_action :set_polling_header
  around_action :allow_gitaly_ref_name_caching

  def widget
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
    Gitlab::PollingInterval.set_header(response, interval: 10_000)
  end

  def serializer(entity)
    serializer = MergeRequestSerializer.new(current_user: current_user, project: merge_request.project)
    serializer.represent(merge_request, {}, entity)
  end
end
