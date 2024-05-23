# frozen_string_literal: true

module Resolvers
  module Projects
    class UserContributedProjectsResolver < BaseResolver
      type Types::ProjectType.connection_type, null: true

      argument :sort, Types::Projects::ProjectSortEnum,
        description: 'Sort contributed projects.',
        required: false,
        default_value: :latest_activity_desc

      alias_method :user, :object

      def resolve(**args)
        ContributedProjectsFinder.new(user).execute(current_user, order_by: args[:sort]).joined(user)
      end
    end
  end
end
