# frozen_string_literal: true

module Types
  class DependencyProxy::ImageTtlGroupPolicyType < BaseObject
    graphql_name 'DependencyProxyImageTtlGroupPolicy'

    description 'Group-level Dependency Proxy TTL policy settings'

    authorize :admin_dependency_proxy

    field :created_at, Types::TimeType, null: true, description: 'Timestamp of creation.'
    field :enabled, GraphQL::Types::Boolean, null: false, description: 'Indicates whether the policy is enabled or disabled.'
    field :ttl, GraphQL::Types::Int, null: true, description: 'Number of days to retain a cached image file.'
    field :updated_at, Types::TimeType, null: true, description: 'Timestamp of the most recent update.'
  end
end
