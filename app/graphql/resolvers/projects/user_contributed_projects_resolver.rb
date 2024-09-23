# frozen_string_literal: true

module Resolvers
  module Projects
    class UserContributedProjectsResolver < BaseResolver
      type Types::ProjectType.connection_type, null: true

      argument :sort, Types::Projects::ProjectSortEnum,
        description: 'Sort contributed projects.',
        required: false,
        default_value: :latest_activity_desc

      argument :min_access_level, ::Types::AccessLevelEnum,
        required: false,
        description: 'Return only projects where current user has at least the specified access level.'

      alias_method :user, :object

      def resolve(**args)
        ContributedProjectsFinder.new(
          user: user,
          current_user: current_user,
          params: {
            order_by: args[:sort],
            min_access_level: args[:min_access_level]
          }
        ).execute.joined(user)
      end
    end
  end
end
