# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType -- inherited from ResolvesSnippets

module Resolvers
  class SnippetsResolver < BaseResolver
    include ResolvesIds
    include ResolvesSnippets

    ERROR_MESSAGE = 'Filtering by both an author and a project is not supported'

    alias_method :user, :object

    argument :author_id, ::Types::GlobalIDType[::User],
      required: false,
      description: 'ID of an author.'

    argument :project_id, ::Types::GlobalIDType[::Project],
      required: false,
      description: 'ID of a project.'

    argument :type, Types::Snippets::TypeEnum,
      required: false,
      description: 'Type of snippet.'

    argument :explore,
      GraphQL::Types::Boolean,
      required: false,
      description: 'Explore personal snippets.'

    def resolve(**args)
      if args[:author_id].present? && args[:project_id].present?
        raise Gitlab::Graphql::Errors::ArgumentError, ERROR_MESSAGE
      end

      super
    end

    private

    def snippet_finder_params(args)
      super
        .merge(author: resolve_ids(args[:author_id]),
          project: resolve_ids(args[:project_id]),
          explore: args[:explore])
    end
  end
end
# rubocop:enable Graphql/ResolverType
