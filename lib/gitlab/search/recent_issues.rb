# frozen_string_literal: true

module Gitlab
  module Search
    class RecentIssues < RecentItems
      private

      def type
        Issue
      end

      def finder
        IssuesFinder
      end
    end
  end
end
