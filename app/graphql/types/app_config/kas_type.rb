# frozen_string_literal: true

module Types
  module AppConfig
    class KasType < ::Types::BaseObject
      graphql_name 'Kas'

      authorize :read_instance_metadata

      field :enabled, GraphQL::Types::Boolean, null: false,
        description: 'Indicates whether the Kubernetes agent server is enabled.'
      field :external_k8s_proxy_url, GraphQL::Types::String, null: true,
        description: 'URL used by the Kubernetes tooling to communicate with the KAS Kubernetes API proxy.'
      # rubocop:disable GraphQL/ExtractType -- we want to keep this way for backwards compatibility
      field :external_url, GraphQL::Types::String, null: true,
        description: 'URL used by the agents to communicate with the server.'
      # rubocop:enable GraphQL/ExtractType
      field :version, GraphQL::Types::String, null: true,
        description: 'KAS version.'
    end
  end
end
