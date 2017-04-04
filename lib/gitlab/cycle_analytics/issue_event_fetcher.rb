module Gitlab
  module CycleAnalytics
    class IssueEventFetcher < BaseEventFetcher
      include IssueAllowed

      def initialize(*args)
        @projections = [issue_table[:title],
                        issue_table[:iid],
                        issue_table[:id],
                        issue_table[:created_at],
                        issue_table[:author_id]]

        super(*args)
      end

      private

      def serialize(event)
        AnalyticsIssueSerializer.new(project: @project).represent(event)
      end
    end
  end
end
