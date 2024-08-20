# frozen_string_literal: true

module Types
  module Projects
    # rubocop: disable Graphql/AuthorizeTypes
    class ForkDetailsType < BaseObject
      graphql_name 'ForkDetails'
      description 'Details of the fork project compared to its upstream project.'

      field :ahead, GraphQL::Types::Int,
        null: true,
        calls_gitaly: true,
        description: 'Number of commits ahead of upstream.'

      field :behind, GraphQL::Types::Int,
        null: true,
        calls_gitaly: true,
        description: 'Number of commits behind upstream.'

      field :is_syncing, GraphQL::Types::Boolean,
        null: true,
        method: :syncing?,
        description: 'Indicates if there is a synchronization in progress.'

      field :has_conflicts, GraphQL::Types::Boolean,
        null: true,
        method: :has_conflicts?,
        description: 'Indicates if the fork conflicts with its upstream project.'

      def ahead
        counts[:ahead]
      end

      def behind
        counts[:behind]
      end

      def counts
        @counts ||= object.counts
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
