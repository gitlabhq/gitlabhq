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

          # Authorization is handled by each Search class (RecentWorkItems, RecentIssues, etc.)
          recent_items_service.latest_with_timestamps.each do |item, timestamp|
            all_items << RecentlyViewedItem.new(item, timestamp) if authorized_to_read_item?(item)
          end
        end

        # Sort by viewed_at descending (most recent first)
        all_items.sort_by { |entry| -entry.viewed_at.to_f }
      end

      private

      def available_types
        [::Gitlab::Search::RecentWorkItems, ::Gitlab::Search::RecentMergeRequests, ::Gitlab::Search::RecentWikiPages]
      end

      # This method is overridden in EE to add Epic authorization.
      # For CE items, we double-check authorization here as a safety layer.
      def authorized_to_read_item?(item)
        case item
        when WorkItem
          Ability.allowed?(current_user, :read_work_item, item)
        when Issue
          Ability.allowed?(current_user, :read_issue, item)
        when MergeRequest
          Ability.allowed?(current_user, :read_merge_request, item)
        when WikiPage::Meta
          Ability.allowed?(current_user, :read_wiki, item)
        else
          # Unknown item types should be filtered out
          false
        end
      end
    end
  end
end

Resolvers::Users::RecentlyViewedItemsResolver.prepend_mod
