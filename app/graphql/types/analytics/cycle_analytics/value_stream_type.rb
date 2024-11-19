# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      class ValueStreamType < BaseObject
        graphql_name 'ValueStream'

        authorize :read_cycle_analytics

        field :id,
          type: ::Types::GlobalIDType[::Analytics::CycleAnalytics::ValueStream],
          null: false,
          description: "ID of the value stream."

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
          experiment: { milestone: '15.6' }

        field :stages,
          null: true,
          resolver: Resolvers::Analytics::CycleAnalytics::StagesResolver,
          description: 'Value Stream stages.'
      end
    end
  end
end
