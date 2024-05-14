# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType -- inherited from ResolvesSnippets

module Resolvers
  module Users
    class SnippetsResolver < BaseResolver
      include ResolvesSnippets
      include Gitlab::Allowable

      alias_method :user, :object

      argument :type, Types::Snippets::TypeEnum,
        required: false,
        description: 'Type of snippet.'

      private

      def resolve_snippets(_args)
        return Snippet.none unless Ability.allowed?(current_user, :read_user_profile, user)

        super
      end

      def snippet_finder_params(args)
        super.merge(author: user)
      end
    end
  end
end
# rubocop:enable Graphql/ResolverType
