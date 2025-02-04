# frozen_string_literal: true

module Resolvers
  module Users
    class RecentlyViewedIssuesResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type [Types::IssueType], null: true

      authorize :read_user
      authorizes_object!

      def resolve
        recent_issues = ::Gitlab::Search::RecentIssues.new(user: current_user)
        recent_issues.search(nil) # nil skips filtering results by title or description
      end
    end
  end
end
