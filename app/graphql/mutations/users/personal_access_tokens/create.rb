# frozen_string_literal: true

module Mutations
  module Users
    module PersonalAccessTokens
      class Create < BaseMutation
        graphql_name 'PersonalAccessTokenCreate'
        description 'Creates a personal access token for the current user.'

        authorize_granular_token permissions: :create_personal_access_token,
          boundary: :user,
          boundary_type: :user

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

        argument :sudo, GraphQL::Types::Boolean,
          required: false,
          default_value: false,
          description: 'Whether the token can impersonate other users with sudo. ' \
            'Requires the token owner to be an administrator.'

        argument :granular_scopes, [::Mutations::Authz::AccessTokens::GranularScopeInputType],
          required: true,
          description: 'List of granular scopes to assign to the token.'

        def resolve(**args)
          if Feature.disabled?(:granular_personal_access_tokens, current_user)
            raise_resource_not_available_error! '`granular_personal_access_tokens` feature flag is disabled.'
          end

          granular_scopes = build_granular_scopes(args.delete(:granular_scopes))

          if (calling_token = context[:access_token]).try(:granular?)
            escalation_check = ::Authz::Tokens::PrivilegeEscalationCheck.new(granular_scopes, calling_token).execute
            raise_resource_not_available_error!(escalation_check.message) if escalation_check.error?

            validate_sudo_not_escalated!(args[:sudo], calling_token)
          end

          response = ::Authn::PersonalAccessTokens::CreateGranularService.new(
            current_user: current_user,
            organization: Current.organization,
            params: args.merge(creation_source: PersonalAccessToken::CREATION_SOURCE_API),
            granular_scopes: granular_scopes
          ).execute

          return { errors: Array(response.message) } if response.error?

          token = response[:personal_access_token]

          { token: token.token, errors: [] }
        end

        private

        def build_granular_scopes(inputs)
          boundary_rule = ::Authz::GranularScopes::ReadBoundaryRule.new(current_user)
          builder_inputs = inputs.map { |input| granular_scope_builder_input(input) }

          ::Authz::GranularScopes::Builder.new(builder_inputs, boundary_rule: boundary_rule).build
        rescue ::Authz::GranularScopes::Builder::ResourceNotAllowedError
          raise_resource_not_available_error!
        end

        def granular_scope_builder_input(input)
          {
            access: input.access,
            permissions: input.permissions,
            resources: selected_resources(input)
          }
        end

        def selected_resources(input)
          return [] unless input.access.to_sym == ::Authz::GranularScope::Access::SELECTED_MEMBERSHIPS

          ids_by_type = GitlabSchema.parse_gids(input.resource_ids).group_by { |gid| gid.model_class.name }
          groups = batch_load(ids_by_type.fetch('Group', []))
          projects = batch_load(ids_by_type.fetch('Project', []), [:project_namespace])

          # Queue both loaders before the first sync so each model class loads in one query
          (groups + projects).filter_map(&:sync)
        end

        def batch_load(gids, preloads = [])
          gids.map do |gid|
            ::Gitlab::Graphql::Loaders::BatchModelLoader.new(gid.model_class, gid.model_id, preloads).find
          end
        end

        def validate_sudo_not_escalated!(sudo, calling_token)
          return unless sudo
          return if calling_token.try(:sudo?)

          raise_resource_not_available_error!(
            'A granular token without sudo cannot create a token with sudo.'
          )
        end
      end
    end
  end
end
