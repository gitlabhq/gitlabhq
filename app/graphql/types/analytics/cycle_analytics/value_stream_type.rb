# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      class ValueStreamType < BaseObject
        graphql_name 'ValueStream'

        authorize :read_cycle_analytics

        field :name,
          GraphQL::Types::String,
          null: false,
          description: 'Name of the value stream.'

        field :namespace, Types::NamespaceType,
          null: false,
          description: 'Namespace the value stream belongs to.'

        field :project, Types::ProjectType,
          null: true,
          description: 'Project the value stream belongs to, returns empty if it belongs to a group.',
          alpha: { milestone: '15.6' }
      end
    end
  end
end
