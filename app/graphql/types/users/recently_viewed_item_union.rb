# frozen_string_literal: true

module Types
  module Users
    class RecentlyViewedItemUnion < BaseUnion
      graphql_name 'RecentlyViewedItemUnion'

      possible_types Types::IssueType, Types::WorkItemType, Types::MergeRequestType, Types::Wikis::WikiPageType

      def self.resolve_type(object, context)
        case object
        when ::WorkItem
          # Return WorkItemType when feature flag is enabled, otherwise IssueType for backward compatibility
          if ::Feature.enabled?(:work_items_autocomplete, context[:current_user])
            Types::WorkItemType
          else
            Types::IssueType
          end
        when ::Issue
          Types::IssueType
        when ::MergeRequest
          Types::MergeRequestType
        when ::WikiPage::Meta
          Types::Wikis::WikiPageType
        else
          raise "Unexpected RecentlyViewedItem type: #{object.class}"
        end
      end
    end
  end
end

Types::Users::RecentlyViewedItemUnion.prepend_mod
