# frozen_string_literal: true

module Types
  module Users
    class RecentlyViewedItemUnion < BaseUnion
      graphql_name 'RecentlyViewedItemUnion'

      possible_types Types::IssueType, Types::MergeRequestType

      def self.resolve_type(object, _context)
        case object
        when ::Issue
          Types::IssueType
        when ::MergeRequest
          Types::MergeRequestType
        else
          raise "Unexpected RecentlyViewedItem type: #{object.class}"
        end
      end
    end
  end
end

Types::Users::RecentlyViewedItemUnion.prepend_mod
