# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class ReviewEventFetcher < BaseEventFetcher
      include ReviewHelper

      def initialize(*args)
        @projections = [mr_table[:title],
                        mr_table[:iid],
                        mr_table[:id],
                        mr_table[:created_at],
                        mr_table[:state],
                        mr_table[:author_id],
                        projects_table[:name],
                        routes_table[:path]]

        super(*args)
      end

      private

      def serialize(event)
        AnalyticsMergeRequestSerializer.new(serialization_context).represent(event)
      end

      def allowed_ids_finder_class
        MergeRequestsFinder
      end
    end
  end
end
