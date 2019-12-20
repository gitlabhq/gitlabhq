# frozen_string_literal: true

module Resolvers
  module Projects
    class SnippetsResolver < BaseResolver
      include ResolvesSnippets

      alias_method :project, :object

      def resolve(**args)
        return Snippet.none if project.nil?

        super
      end

      private

      def snippet_finder_params(args)
        super.merge(project: project)
      end
    end
  end
end
