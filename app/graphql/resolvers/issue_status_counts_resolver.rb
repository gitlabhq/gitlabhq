# frozen_string_literal: true

module Resolvers
  class IssueStatusCountsResolver < Issues::BaseResolver
    type Types::IssueStatusCountsType, null: true

    accept_release_tag

    def resolve(**args)
      return Issue.none if resource_parent.nil?

      finder = IssuesFinder.new(current_user, prepare_finder_params(args))
      finder.parent_param = resource_parent

      Gitlab::IssuablesCountForState.new(finder, resource_parent)
    end

    private

    def resource_parent
      # The project could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project to query for issues, so
      # make sure it's loaded and not `nil` before continuing.
      strong_memoize(:resource_parent) do
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end
