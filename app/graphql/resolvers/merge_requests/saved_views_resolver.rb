# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class SavedViewsResolver < BaseResolver
      type ::Types::MergeRequests::SavedViewType.connection_type, null: true

      def resolve(**_args)
        return ::MergeRequests::SavedView.none unless Feature.enabled?(:mr_dashboard_saved_views, current_user)

        ::MergeRequests::SavedViewsFinder.new(current_user).execute
      end
    end
  end
end
