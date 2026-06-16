# frozen_string_literal: true

module MergeRequests
  class BaseCloudEvent < Gitlab::EventStore::CloudEvent
    event_category :merge_requests

    class << self
      protected

      def build_for_merge_request(merge_request:, current_user:, extra_event_data: {})
        build_cloud_event(
          source: "projects/#{merge_request.project.id}",
          subject: "merge_requests/#{merge_request.id}",
          current_user: current_user,
          organization: merge_request.project.organization,
          event_data: merge_request_event_data(merge_request).merge(extra_event_data)
        )
      end

      private

      def merge_request_event_data(merge_request)
        {
          merge_request_id: merge_request.id,
          merge_request_iid: merge_request.iid,
          project_id: merge_request.project_id
        }
      end
    end

    def data_schema
      {
        'type' => 'object',
        'properties' => base_properties.merge(additional_properties),
        'required' => base_required + additional_required
      }
    end

    private

    def base_properties
      {
        'merge_request_id' => { 'type' => 'integer' },
        'merge_request_iid' => { 'type' => 'integer' },
        'project_id' => { 'type' => 'integer' }
      }
    end

    def base_required
      %w[merge_request_id merge_request_iid project_id]
    end

    # Override in subclasses to add event specific schema properties
    def additional_properties
      {}
    end

    # Override in subclasses to add event specific required fields
    def additional_required
      []
    end
  end
end
