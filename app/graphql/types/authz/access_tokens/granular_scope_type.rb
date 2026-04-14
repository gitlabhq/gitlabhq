# frozen_string_literal: true

module Types
  module Authz
    module AccessTokens
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization handled in the resolver
      class GranularScopeType < BaseObject
        graphql_name 'AccessTokenGranularScope'
        description 'Granular scope applied to an access token.'

        field :access,
          Types::Authz::AccessTokens::GranularScopeAccessEnum,
          null: false,
          description: 'Access configured on a granular scope.'

        field :namespace,
          Types::NamespaceType,
          null: true,
          description: 'Namespace of the granular scope.'

        field :project,
          Types::ProjectType,
          null: true,
          description: 'Project of the granular scope, when the scope targets a specific project.'

        field :permissions,
          [Types::Authz::AccessTokens::PermissionType],
          null: true,
          description: 'List of permissions of a granular scope.'

        def project
          return unless object.namespace.is_a?(::Namespaces::ProjectNamespace)

          BatchLoader::GraphQL.for(object.namespace.id).batch do |namespace_ids, loader|
            ::Project.by_project_namespace(namespace_ids).find_each do |proj|
              loader.call(proj.project_namespace_id, proj)
            end
          end
        end

        def permissions
          object.permissions.filter_map { |permission_name| ::Authz::PermissionGroups::Assignable.get(permission_name) }
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
