# frozen_string_literal: true

module Types
  class DependencyProxy::GroupSettingType < BaseObject
    graphql_name 'DependencyProxySetting'

    description 'Group-level Dependency Proxy settings'

    authorize :admin_dependency_proxy

    field :enabled, GraphQL::Types::Boolean, null: false, description: 'Indicates whether the dependency proxy is enabled for the group.'
    field :identity, GraphQL::Types::String, null: true,
      experiment: { milestone: '17.10' },
      description: 'Identity credential used to authenticate with Docker Hub when pulling images. ' \
        'Can be a username (for password or PAT) or organization name (for OAT). ' \
        'Returns null if `dependency_proxy_containers_docker_hub_credentials` feature flag is disabled.'

    def identity
      object.identity if Feature.enabled?(:dependency_proxy_containers_docker_hub_credentials, object.group)
    end
  end
end
