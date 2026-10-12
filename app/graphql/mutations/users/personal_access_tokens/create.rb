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
          builder_inputs = inputs.map { |input| builder_input_for(input) }

          ::Authz::GranularScopes::Builder.new(builder_inputs, boundary_rule: boundary_rule).build
        rescue ::Authz::GranularScopes::Builder::ResourceNotAllowedError
          raise_resource_not_available_error!
        end

        # resource_ids may hold Global IDs of any model; only groups and projects can bound a scope
        def builder_input_for(input)
          ids_by_model = Array(input.resource_ids).group_by(&:model_class)

          {
            access: input.access,
            permissions: input.permissions,
            group_ids: ids_by_model.fetch(::Group, []).map(&:model_id),
            project_ids: ids_by_model.fetch(::Project, []).map(&:model_id)
          }
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
