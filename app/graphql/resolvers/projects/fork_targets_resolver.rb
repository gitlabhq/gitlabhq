# frozen_string_literal: true

module Resolvers
  module Projects
    class ForkTargetsResolver < BaseResolver
      include ResolvesGroups
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::NamespaceType.connection_type, null: true

      authorize :fork_project
      authorizes_object!

      alias_method :project, :object

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search query for path or name.'

      private

      def resolve_groups(**args)
        ForkTargetsFinder.new(project, current_user).execute(args)
      end
    end
  end
end
