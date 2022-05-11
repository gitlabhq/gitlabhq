# frozen_string_literal: true

module Types
  class DependencyProxy::GroupSettingType < BaseObject
    graphql_name 'DependencyProxySetting'

    description 'Group-level Dependency Proxy settings'

    authorize :admin_dependency_proxy

    field :enabled, GraphQL::Types::Boolean, null: false, description: 'Indicates whether the dependency proxy is enabled for the group.'
  end
end
