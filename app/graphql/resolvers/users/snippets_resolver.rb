# frozen_string_literal: true

module Resolvers
  module Users
    class SnippetsResolver < BaseResolver
      include ResolvesSnippets

      alias_method :user, :object

      argument :type, Types::Snippets::TypeEnum,
               required: false,
               description: 'The type of snippet'

      private

      def snippet_finder_params(args)
        super.merge(author: user)
      end
    end
  end
end
