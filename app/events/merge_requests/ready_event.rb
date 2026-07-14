# frozen_string_literal: true

module MergeRequests
  class ReadyEvent < BaseCloudEvent
    event_type :ready

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
