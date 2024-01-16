# frozen_string_literal: true

module Resolvers
  module Projects
    class ForkTargetsResolver < BaseResolver
      include LooksAhead
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::NamespaceType.connection_type, null: true

      authorize :fork_project
      authorizes_object!

      alias_method :project, :object

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search query for path or name.'

      def resolve_with_lookahead(**args)
        fork_targets = ForkTargetsFinder.new(project, current_user).execute(args)
        apply_lookahead(fork_targets)
      end

      private

      def preloads
        ResolvesGroups::PRELOADS
      end
    end
  end
end
