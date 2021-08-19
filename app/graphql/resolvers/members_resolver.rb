# frozen_string_literal: true

module Resolvers
  class MembersResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include LooksAhead

    type Types::MemberInterface.connection_type, null: true

    argument :search, GraphQL::Types::String,
              required: false,
              description: 'Search query.'

    def resolve_with_lookahead(**args)
      authorize!(object)

      relations = args.delete(:relations)

      apply_lookahead(finder_class.new(object, current_user, params: args).execute(include_relations: relations))
    end

    private

    def preloads
      {
        user: [:user, :source]
      }
    end

    def finder_class
      # override in subclass
    end
  end
end
