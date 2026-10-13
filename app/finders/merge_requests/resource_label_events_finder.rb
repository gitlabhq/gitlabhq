# frozen_string_literal: true

module MergeRequests
  class ResourceLabelEventsFinder
    def initialize(merge_request, params = {})
      @merge_request = merge_request
      @params = params
    end

    def execute
      events = merge_request.resource_label_events.inc_relations.with_merge_request_project_ordered

      return events unless params[:label_id]

      events.with_label_id(params[:label_id])
    end

    private

    attr_reader :merge_request, :params
  end
end
