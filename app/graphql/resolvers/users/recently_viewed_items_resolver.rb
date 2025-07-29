# frozen_string_literal: true

module Resolvers
  module Users
    class RecentlyViewedItemsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type [Types::Users::RecentlyViewedItemType], null: true

      authorize :read_user

      RecentlyViewedItem = Struct.new(:item, :viewed_at)

      def resolve
        all_items = []

        available_types.each do |klass|
          recent_items_service = klass.new(user: current_user)

          recent_items_service.latest_with_timestamps.each do |item, timestamp|
            all_items << RecentlyViewedItem.new(item, timestamp)
          end
        end

        # Sort by viewed_at descending (most recent first)
        all_items.sort_by { |entry| -entry.viewed_at.to_f }
      end

      private

      def available_types
        [::Gitlab::Search::RecentIssues, ::Gitlab::Search::RecentMergeRequests]
      end
    end
  end
end
