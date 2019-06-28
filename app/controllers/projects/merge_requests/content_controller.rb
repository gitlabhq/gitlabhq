# frozen_string_literal: true

class Projects::MergeRequests::ContentController < Projects::MergeRequests::ApplicationController
  # @merge_request.check_mergeability is not executed here since
  # widget serializer calls it via mergeable? method
  # but we might want to call @merge_request.check_mergeability
  # for other types of serialization

  before_action :close_merge_request_if_no_source_project
  around_action :allow_gitaly_ref_name_caching

  def widget
    respond_to do |format|
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        serializer = MergeRequestSerializer.new(current_user: current_user, project: merge_request.project)
        render json: serializer.represent(merge_request, serializer: 'widget')
      end
    end
  end
end
