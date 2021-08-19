# frozen_string_literal: true

module Types
  module Metadata
    class KasType < ::Types::BaseObject
      graphql_name 'Kas'

      authorize :read_instance_metadata

      field :enabled, GraphQL::Types::Boolean, null: false,
            description: 'Indicates whether the Kubernetes Agent Server is enabled.'
      field :version, GraphQL::Types::String, null: true,
            description: 'KAS version.'
      field :external_url, GraphQL::Types::String, null: true,
            description: 'The URL used by the Agents to communicate with KAS.'
    end
  end
end
