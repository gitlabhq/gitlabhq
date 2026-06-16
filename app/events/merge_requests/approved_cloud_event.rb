# frozen_string_literal: true

module MergeRequests
  class ApprovedCloudEvent < BaseCloudEvent
    event_type :approved

    class << self
      def build(merge_request:, current_user:, approval:)
        build_for_merge_request(
          merge_request: merge_request,
          current_user: current_user,
          extra_event_data: { approved_at: approval.created_at.iso8601(6) }
        )
      end
    end

    private

    def additional_properties
      { 'approved_at' => { 'type' => 'string', 'format' => 'date-time' } }
    end

    def additional_required
      %w[approved_at]
    end
  end
end
