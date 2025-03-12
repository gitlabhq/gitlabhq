# frozen_string_literal: true

module Types
  class DependencyProxy::GroupSettingType < BaseObject
    graphql_name 'DependencyProxySetting'

    description 'Group-level Dependency Proxy settings'

    authorize :admin_dependency_proxy

    field :enabled, GraphQL::Types::Boolean, null: false, description: 'Indicates whether the dependency proxy is enabled for the group.'
    field :identity, GraphQL::Types::String, null: true,
      description: 'Identity credential used to authenticate with Docker Hub when pulling images. ' \
        'Can be a username (for password or personal access token (PAT)) or organization name (for organization access token (OAT)).'
  end
end
