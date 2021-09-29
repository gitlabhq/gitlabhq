# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class RunnerWebUrlEdge < GraphQL::Types::Relay::BaseEdge
      include FindClosest

      field :web_url, GraphQL::Types::String, null: true,
            description: 'Web URL of the runner. The value depends on where you put this field in the query. You can use it for projects or groups.',
            extras: [:parent]

      def initialize(node, connection)
        super

        @runner = node.node
      end

      def web_url(parent:)
        owner = closest_parent([::Types::ProjectType, ::Types::GroupType], parent)

        case owner
        when ::Group
          Gitlab::Routing.url_helpers.group_runner_url(owner, @runner)
        when ::Project
          Gitlab::Routing.url_helpers.project_runner_url(owner, @runner)
        end
      end
    end
  end
end
