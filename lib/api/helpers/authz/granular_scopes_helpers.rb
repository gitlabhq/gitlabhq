# frozen_string_literal: true

module API
  module Helpers
    module Authz
      module GranularScopesHelpers
        extend Grape::API::Helpers

        GRANULAR_SCOPE_ACCESS_VALUES = ::Authz::GranularScope::Access::LEVELS.keys.map(&:to_s).freeze

        params :granular_scope_params do
          optional :granular_scopes, type: Array, desc: 'List of granular scopes to assign.' do
            requires :access, type: String, values: GRANULAR_SCOPE_ACCESS_VALUES,
              desc: 'Access to configure for the granular scope.'
            requires :permissions, type: Array[String], desc: 'List of permissions for the granular scope.'
            optional :project_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
              desc: 'IDs of projects to associate with the granular scope, when access is `selected_memberships`.'
            optional :group_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
              desc: 'IDs of groups to associate with the granular scope, when access is `selected_memberships`.'
          end
        end

        # @param user [User] owner of the scopes; each resource must be a boundary the user can read
        # @param inputs [Array<Hash>] the declared :granular_scopes params
        # @return [Array<Authz::GranularScope>] unsaved scopes; renders 404 when a resource is refused
        def build_granular_scopes(user, inputs)
          boundary_rule = ::Authz::GranularScopes::ReadBoundaryRule.new(user)

          ::Authz::GranularScopes::Builder.new(inputs, boundary_rule: boundary_rule).build
        rescue ::Authz::GranularScopes::Builder::ResourceNotAllowedError
          not_found!
        end

        def project_ids_by_namespace_id_for(tokens)
          namespaces = Array(tokens).flat_map(&:granular_scopes).filter_map(&:namespace)
          project_namespace_ids = namespaces.select { |namespace| namespace.is_a?(::Namespaces::ProjectNamespace) }
            .map(&:id)

          return {} if project_namespace_ids.empty?

          ::Project.ids_by_project_namespace_id(project_namespace_ids)
        end

        # Returns the options the token entities (API::Entities::PersonalAccessToken and every entity
        # that inherits from it) need to expose the granular scopes of the given tokens, after preloading
        # those scopes with their namespaces. Only a granular token has scopes to present, so a token that
        # is not granular is left out of the preload, and tokens with none among them get no options and
        # run no query. Scopes that are already loaded, such as through
        # PersonalAccessToken.preload_granular_scopes, are not reloaded.
        #
        # The namespaces are preloaded on the scopes each token holds, in a second step. Preloading
        # { granular_scopes: :namespace } in one step would load them onto other copies of the scopes,
        # read through the join rows, whenever a token already holds its scopes without their namespaces,
        # as a token that CreateGranularService returns does, and the entity would then load the namespace
        # of each scope it presents.
        def granular_scopes_options_for(tokens)
          granular_tokens = Array(tokens).select(&:granular?)
          return {} if granular_tokens.empty?

          ActiveRecord::Associations::Preloader.new(records: granular_tokens, associations: :granular_scopes).call
          ActiveRecord::Associations::Preloader.new(
            records: granular_tokens.flat_map(&:granular_scopes), associations: :namespace
          ).call

          {
            with_granular_scopes: true,
            project_ids_by_namespace_id: project_ids_by_namespace_id_for(granular_tokens)
          }
        end
      end
    end
  end
end
