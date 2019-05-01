# frozen_string_literal: true

module Types
  class GroupType < NamespaceType
    graphql_name 'Group'

    authorize :read_group

    expose_permissions Types::PermissionTypes::Group

    field :web_url, GraphQL::STRING_TYPE, null: true

    field :avatar_url, GraphQL::STRING_TYPE, null: true, resolve: -> (group, args, ctx) do
      group.avatar_url(only_path: false)
    end

    if ::Group.supports_nested_objects?
      field :parent, GroupType, null: true
    end
  end
end
