# frozen_string_literal: true

module Mutations
  module Users
    module PersonalAccessTokens
      class Create < BaseMutation
        graphql_name 'PersonalAccessTokenCreate'
        description 'Creates a personal access token for the current user.'

        field :token, GraphQL::Types::String,
          null: true,
          description: 'Created personal access token.'

        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the token.'

        argument :description, GraphQL::Types::String,
          required: false,
          description: 'Description of the token.'

        argument :expires_at, GraphQL::Types::ISO8601Date,
          required: false,
          description: 'Expiration date of the token.'

        argument :granular_scopes, [::Mutations::Authz::AccessTokens::GranularScopeInputType],
          required: true,
          description: 'List of granular scopes to assign to the token.'

        attr_reader :granular_scopes

        def resolve(**args)
          if Feature.disabled?(:granular_personal_access_tokens, current_user)
            raise_resource_not_available_error! '`granular_personal_access_tokens` feature flag is disabled.'
          end

          granular_scopes = build_granular_scopes(args.delete(:granular_scopes))
          response = ::Authn::PersonalAccessTokens::CreateGranularService.new(
            current_user: current_user,
            organization: Current.organization,
            params: args,
            granular_scopes: granular_scopes
          ).execute

          return { errors: Array(response.message) } if response.error?

          token = response[:personal_access_token]

          { token: token.token, errors: [] }
        end

        private

        def build_granular_scopes(inputs)
          attrs = inputs.flat_map { |input| prepare_granular_scope_attrs(input) }

          @granular_scopes ||= attrs.map { |a| ::Authz::GranularScope.new(a) }
        end

        def prepare_granular_scope_attrs(input)
          base_attrs = input.to_h.except(:resource_ids)

          case input.access.to_sym
          when ::Authz::GranularScope::Access::SELECTED_MEMBERSHIPS
            ids_by_type = GitlabSchema.parse_gids(input.resource_ids).group_by { |gid| gid.model_class.name }

            projects = batch_load(ids_by_type.fetch('Project', []), [:project_namespace])
            project_scopes = build_resource_scopes(projects, base_attrs)

            groups = batch_load(ids_by_type.fetch('Group', []))
            group_scopes = build_resource_scopes(groups, base_attrs)

            group_scopes + project_scopes
          when ::Authz::GranularScope::Access::PERSONAL_PROJECTS
            base_attrs.merge(namespace: boundary!(current_user).namespace)
          else
            # namespace_id is nil for all_memberships, user, and instance access
            base_attrs
          end
        end

        def batch_load(gids, preloads = [])
          gids.map do |gid|
            ::Gitlab::Graphql::Loaders::BatchModelLoader.new(gid.model_class, gid.model_id, preloads).find
          end
        end

        def build_resource_scopes(resources, scope_attrs)
          resources.filter_map do |resource|
            loaded = resource.sync
            next unless loaded

            scope_attrs.merge(namespace: boundary!(loaded).namespace)
          end
        end

        def boundary!(resource)
          ::Authz::Boundary.for(resource).tap do |boundary|
            next if boundary.member?(current_user)

            raise_resource_not_available_error!
          end
        end
      end
    end
  end
end
