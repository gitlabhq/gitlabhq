# frozen_string_literal: true

module Types
  module Packages
    module Helm
      # rubocop: disable Graphql/AuthorizeTypes
      class MetadataType < BaseObject
        graphql_name 'PackageHelmMetadataType'
        description 'Represents the contents of a Helm Chart.yml file'

        # Need to be synced with app/validators/json_schemas/helm_metadata.json
        field :annotations, GraphQL::Types::JSON, null: true, description: 'Annotations for the chart.' # rubocop:disable Graphql/JSONType
        field :api_version,
          GraphQL::Types::String,
          null: false,
          description: 'API version of the chart.',
          hash_key: :apiVersion
        field :app_version,
          GraphQL::Types::String,
          null: true,
          description: 'App version of the chart.',
          hash_key: :appVersion
        field :condition, GraphQL::Types::String, null: true, description: 'Condition for the chart.'
        field :dependencies, [Types::Packages::Helm::DependencyType], null: true,
          description: 'Dependencies of the chart.'
        field :deprecated, GraphQL::Types::Boolean, null: true, description: 'Indicates if the chart is deprecated.'
        field :description, GraphQL::Types::String, null: true, description: 'Description of the chart.'
        field :home, GraphQL::Types::String, null: true, description: 'URL of the home page.'
        field :icon, GraphQL::Types::String, null: true, description: 'URL to an SVG or PNG image for the chart.'
        field :keywords, [GraphQL::Types::String], null: true, description: 'Keywords for the chart.'
        field :kube_version,
          GraphQL::Types::String,
          null: true,
          description: 'Kubernetes versions for the chart.',
          hash_key: :kubeVersion
        field :maintainers, [Types::Packages::Helm::MaintainerType], null: true,
          description: 'Maintainers of the chart.'
        field :name, GraphQL::Types::String, null: false, description: 'Name of the chart.'
        field :sources, [GraphQL::Types::String], null: true, description: 'URLs of the source code for the chart.'
        field :tags, GraphQL::Types::String, null: true, description: 'Tags for the chart.'
        field :type, GraphQL::Types::String, null: true, description: 'Type of the chart.', hash_key: :appVersion
        field :version, GraphQL::Types::String, null: false, description: 'Version of the chart.'
      end
    end
  end
end
