# frozen_string_literal: true

module Resolvers
  module Ci
    class UserRunnersResolver < RunnersResolver
      type Types::Ci::RunnerType.connection_type, null: true

      argument :assignable_to_project_path, GraphQL::Types::ID, # rubocop:disable Graphql/IDType -- This is a project_path, and not a generic id.
        required: false,
        description: 'Path of a project. When set, returns runners that can be assigned to a project, ' \
          'are not locked, and not already assigned to the project.'

      protected

      def runners_finder_params(params)
        project = Project.find_by_full_path(params[:assignable_to_project_path])

        super.merge(assignable_to_project: project)
      end

      def parent_param
        raise_resource_not_available_error! unless parent.is_a?(User)

        { user: parent }
      end
    end
  end
end
