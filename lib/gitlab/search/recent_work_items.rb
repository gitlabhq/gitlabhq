# frozen_string_literal: true

module Gitlab
  module Search
    class RecentWorkItems < RecentItems
      extend ::Gitlab::Utils::Override

      override :search
      def search(term)
        query_items_by_ids(term, latest_ids)
      end

      private

      override :query_items_by_ids
      def query_items_by_ids(term, ids)
        return WorkItem.none if ids.empty?

        # Query work items directly to support global search (including group-level items)
        # Similar to RecentEpics approach since WorkItemsFinder requires group context
        work_items = WorkItem
          .inc_relations_for_permission_check
          .id_in_ordered(ids)
          .limit(::Gitlab::Search::RecentItems::SEARCH_LIMIT)
          .preload_namespace
          .preload_routables

        work_items = work_items.full_search(term, matched_columns: 'title') if term.present?

        filter_by_permissions(work_items)
      end

      def filter_by_permissions(items)
        # Manual permission checking since we're not using a finder
        DeclarativePolicy.user_scope do
          items.select { |item| Ability.allowed?(user, :read_work_item, item) }
        end
      end

      # Override to use the same Redis key as RecentIssues since WorkItem < Issue
      # and they represent the same underlying data. This ensures recent items
      # tracked through IssuesController are visible in WorkItems autocomplete.
      def key
        "recent_items:issue:#{user.id}"
      end
    end
  end
end
