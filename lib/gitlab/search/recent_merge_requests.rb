# frozen_string_literal: true

module Gitlab
  module Search
    class RecentMergeRequests < RecentItems
      private

      def type
        MergeRequest
      end

      def finder
        MergeRequestsFinder
      end
    end
  end
end
