# frozen_string_literal: true

module MergeRequests
  class CodeConflictEvent < BaseCloudEvent
    event_type :code_conflict

    class << self
      def build(merge_request:)
        return if merge_request.author.nil?

        build_for_merge_request(
          merge_request: merge_request,
          current_user: merge_request.author
        )
      end
    end
  end
end
