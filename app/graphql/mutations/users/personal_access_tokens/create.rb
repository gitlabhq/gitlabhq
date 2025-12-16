# frozen_string_literal: true

module Mutations
  module Users
    module PersonalAccessTokens
      class Create < BaseMutation
        graphql_name 'PersonalAccessTokenCreate'
        description 'Creates a personal access token for the current user.'

        field :token, Types::Authz::PersonalAccessTokens::PersonalAccessTokenType,
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

          build_granular_scopes(args.delete(:granular_scopes))

          params = personal_access_token_params(args)
          response = ::PersonalAccessTokens::CreateService.new(
            current_user: current_user, target_user: current_user, params: params,
            organization_id: Current.organization.id
          ).execute

          return { errors: Array(response.message) } if response.error?

          token = response.payload[:personal_access_token]

          response = ::Authz::GranularScopeService.new(token).add_granular_scopes(
            granular_scopes
          )

          return { errors: Array(response.message) } if response.error?

          { token: token, errors: [] }
        end

        private

        def personal_access_token_params(args)
          args.merge(granular: true, scopes: [::Gitlab::Auth::GRANULAR_SCOPE])
        end

        def build_granular_scopes(inputs)
          attrs = inputs.flat_map { |input| prepare_granular_scope_attrs(input) }

          @granular_scopes ||= attrs.map { |a| ::Authz::GranularScope.new(a) }
        end

        def prepare_granular_scope_attrs(input)
          base_attrs = input.to_h.except(:resource_ids)

          case input.access
          when 'selected_memberships'
            input.resource_ids.map do |gid|
              resource = ::Gitlab::Graphql::Lazy.force(GitlabSchema.object_from_id(gid))

              raise_resource_not_available_error! unless resource.is_a?(::Group) || resource.is_a?(::Project)

              base_attrs.merge(namespace: boundary!(resource).namespace)
            end
          when 'personal_projects'
            base_attrs.merge(namespace: boundary!(current_user).namespace)
          else
            # namespace_id is nil for all_memberships, user, and instance access
            base_attrs
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
