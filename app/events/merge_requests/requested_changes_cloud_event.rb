# frozen_string_literal: true

module MergeRequests
  # Published for each verdict that requests changes, also when the reviewer already requested changes.
  # A GitLab Duo Code Review verdict has no composite actor in the envelope. `review_workflow_id` names its
  # review session, when Duo Code Review authorized one.
  class RequestedChangesCloudEvent < BaseCloudEvent
    event_type :requested_changes

    class << self
      def build(merge_request:, current_user:, review_workflow_id: nil)
        build_for_merge_request(
          merge_request: merge_request,
          current_user: current_user,
          extra_event_data: { review_workflow_id: review_workflow_id }.compact
        )
      end
    end

    private

    def additional_properties
      { 'review_workflow_id' => { 'type' => 'integer' } }
    end
  end
end
