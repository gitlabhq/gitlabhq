# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class StackResolver < BaseResolver
      prepend ::MergeRequests::LookAheadPreloads

      type [::Types::MergeRequestType], null: true

      alias_method :merge_request, :object

      def resolve_with_lookahead
        relation = ::MergeRequests::StackFinder.new(current_user, merge_request).execute

        apply_lookahead(relation)
      end
    end
  end
end
