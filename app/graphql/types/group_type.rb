# frozen_string_literal: true

module Types
  class GroupType < NamespaceType
    graphql_name 'Group'

    authorize :read_group

    expose_permissions Types::PermissionTypes::Group

    field :web_url, GraphQL::STRING_TYPE, null: false

    field :avatar_url, GraphQL::STRING_TYPE, null: true, resolve: -> (group, args, ctx) do
      group.avatar_url(only_path: false)
    end

    field :parent, GroupType,
          null: true,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, obj.parent_id).find }
  end
end
