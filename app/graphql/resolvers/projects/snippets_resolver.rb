# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType -- inherited from ResolvesSnippets

module Resolvers
  module Projects
    class SnippetsResolver < BaseResolver
      include ResolvesSnippets

      alias_method :project, :object

      def resolve(**args)
        return Snippet.none if project.nil?

        unless project.feature_available?(:snippets, current_user)
          raise_resource_not_available_error! 'Snippets are not enabled for this Project'
        end

        super
      end

      private

      def snippet_finder_params(args)
        super.merge(project: project)
      end
    end
  end
end
# rubocop:enable Graphql/ResolverType
