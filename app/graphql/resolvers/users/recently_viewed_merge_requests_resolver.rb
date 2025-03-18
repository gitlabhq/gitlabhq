# frozen_string_literal: true

module Resolvers
  module Users
    class RecentlyViewedMergeRequestsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type [Types::MergeRequestType], null: true

      authorize :read_user
      authorizes_object!

      def resolve
        recent_merge_requests = ::Gitlab::Search::RecentMergeRequests.new(user: current_user)
        recent_merge_requests.search(nil) # nil skips filtering results by title or description
      end
    end
  end
end
