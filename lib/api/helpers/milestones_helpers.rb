# frozen_string_literal: true

module API
  module Helpers
    module MilestonesHelpers
      extend Grape::API::Helpers

      # Resolves a `:milestone` (title) param into `:milestone_id` and
      # removes the `:milestone` key. If the title does not match any
      # milestone in scope, the field is silently ignored. This matches
      # the behavior of the `:milestone_id` param, which is also dropped
      # by `Issuable::Callbacks::Milestone` when it does not resolve to a
      # milestone in scope.
      def resolve_milestone_title!(container, params)
        return if params[:milestone].blank?

        milestone = ::Issuables::MilestoneTitleResolverService
          .new(container: container, title: params[:milestone])
          .execute

        params[:milestone_id] = milestone.id if milestone
        params.delete(:milestone)
      end
    end
  end
end
