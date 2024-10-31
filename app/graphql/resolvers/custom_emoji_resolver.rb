# frozen_string_literal: true

module Resolvers
  class CustomEmojiResolver < BaseResolver
    include LooksAhead
    include Gitlab::Graphql::Authorize::AuthorizeResource

    authorizes_object!

    authorize :read_custom_emoji

    argument :include_ancestor_groups,
      GraphQL::Types::Boolean,
      required: false,
      default_value: false,
      description: 'Includes custom emoji from parent groups.'

    type Types::CustomEmojiType, null: true

    def resolve_with_lookahead(**args)
      apply_lookahead(::Groups::CustomEmojiFinder.new(object, args).execute)
    end

    private

    def unconditional_includes
      [:group]
    end
  end
end
