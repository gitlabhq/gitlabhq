# frozen_string_literal: true

module Types
  module Security
    class ScanFeatureType < BaseObject # rubocop: disable Graphql/AuthorizeTypes -- Authorization is done at parent level
      graphql_name 'SecurityScanFeature'
      description 'Security scan feature configuration.'

      field :available,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the security scan is available for the project.'

      field :can_enable_by_merge_request,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the security scan can be enabled via merge request.'

      field :configuration_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to configure the security scan.'

      field :configured,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether the security scan is configured for the project.'

      field :meta_info_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to additional information about the security scan.'

      field :on_demand_available,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether on-demand scanning is available for the scan type.'

      field :security_features,
        Types::Security::FeatureType,
        null: true,
        description: 'Additional security features specific to the scan type.'

      field :type,
        GraphQL::Types::String,
        null: false,
        description: 'Type of security scan (e.g., sast, dast, secret_detection).'

      def security_features
        object[:security_features].presence
      end
    end
  end
end
