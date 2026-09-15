# frozen_string_literal: true

module MergeRequests
  # Published once a new merge request is ready for automation: its diff is built and,
  # where possible, its code-owner approval rules are synced against it. Fires for
  # drafts too, unlike `MergeRequests::ReadyEvent`. See
  # `MergeRequests::AfterCreateEventPublisher` for when it is published.
  class AfterCreateCloudEvent < BaseCloudEvent
    event_type :created

    class << self
      def build(merge_request:, current_user:)
        build_for_merge_request(
          merge_request: merge_request,
          current_user: current_user
        )
      end
    end
  end
end
