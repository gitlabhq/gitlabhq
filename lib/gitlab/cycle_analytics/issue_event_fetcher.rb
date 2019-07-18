# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class IssueEventFetcher < BaseEventFetcher
      include IssueHelper

      def initialize(*args)
        @projections = [issue_table[:title],
                        issue_table[:iid],
                        issue_table[:id],
                        issue_table[:created_at],
                        issue_table[:author_id],
                        projects_table[:name],
                        routes_table[:path]]

        super(*args)
      end

      private

      def serialize(event)
        AnalyticsIssueSerializer.new(serialization_context).represent(event)
      end

      def allowed_ids_finder_class
        IssuesFinder
      end
    end
  end
end
