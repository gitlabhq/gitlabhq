# frozen_string_literal: true

module Mutations
  module Snippets
    class Base < BaseMutation
      field :snippet,
        Types::SnippetType,
        null: true,
        description: 'Snippet after mutation.'

      private

      def authorized_resource?(snippet)
        return false if snippet.nil?

        Ability.allowed?(context[:current_user], ability_for(snippet), snippet)
      end

      def ability_for(snippet)
        "#{ability_name}_#{snippet.to_ability_name}".to_sym
      end

      def ability_name
        raise NotImplementedError
      end
    end
  end
end
