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
                        mr_table[:state_id],
                        mr_table[:author_id]]

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
