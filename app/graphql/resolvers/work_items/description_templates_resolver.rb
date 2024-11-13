# frozen_string_literal: true

module Resolvers
  module WorkItems
    class DescriptionTemplatesResolver < BaseResolver
      include LooksAhead

      type Types::WorkItems::TypeType.connection_type, null: true

      argument :name, GraphQL::Types::String,
        required: false,
        description: "Fetches the specific DescriptionTemplate."

      argument :search, GraphQL::Types::String,
        required: false,
        description: "Search for DescriptionTemplates by name."

      def resolve_with_lookahead(**_args)
        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/501097
        []
      end
    end
  end
end
