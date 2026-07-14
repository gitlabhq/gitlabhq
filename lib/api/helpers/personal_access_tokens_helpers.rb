# frozen_string_literal: true

module API
  module Helpers
    module PersonalAccessTokensHelpers
      extend Grape::API::Helpers

      GRANULAR_SCOPE_ACCESS_VALUES = ::Authz::GranularScope::Access::LEVELS.keys.map(&:to_s).freeze

      params :access_token_params do
        optional :revoked, type: Boolean, desc: 'Filter tokens where revoked state matches parameter',
          documentation: { example: false }
        optional :state, type: String, desc: 'Filter tokens which are either active or not',
          values: %w[active inactive], documentation: { example: 'active' }
        optional :created_before, type: DateTime, desc: 'Filter tokens which were created before given datetime',
          documentation: { example: '2022-01-01T00:00:00Z' }
        optional :created_after, type: DateTime, desc: 'Filter tokens which were created after given datetime',
          documentation: { example: '2021-01-01T00:00:00Z' }
        optional :last_used_before, type: DateTime, desc: 'Filter tokens which were used before given datetime',
          documentation: { example: '2021-01-01T00:00:00Z' }
        optional :last_used_after, type: DateTime, desc: 'Filter tokens which were used after given datetime',
          documentation: { example: '2022-01-01T00:00:00Z' }
        optional :expires_before, type: Date, desc: 'Filter tokens which expire before given datetime',
          documentation: { example: '2022-01-01' }
        optional :expires_after, type: Date, desc: 'Filter tokens which expire after given datetime',
          documentation: { example: '2021-01-01' }
        optional :search, type: String, desc: 'Filters tokens by name', documentation: { example: 'token' }
        optional :sort, type: String, desc: 'Sort tokens', documentation: { example: 'created_at_desc' }
      end

      params :create_personal_access_token_params do
        requires :name, type: String, desc: 'The name of the access token', documentation: { example: 'My token' }
        optional :description, type: String, desc: 'The description of the access token',
          documentation: { example: 'A token used for k8s' }
        optional :expires_at, type: Date, desc: "Expiration date of the access token in ISO format (YYYY-MM-DD). " \
                                            "If undefined, the date is set to the maximum allowable lifetime limit.",
          documentation: { example: '2021-01-31' }
      end

      params :granular_scope_params do
        optional :granular_scopes, type: Array, desc: 'List of granular scopes to assign to the token' do
          requires :access, type: String, values: GRANULAR_SCOPE_ACCESS_VALUES,
            desc: 'Access to configure for the granular scope.'
          requires :permissions, type: Array[String], desc: 'List of permissions for the granular scope'
          optional :project_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
            desc: 'IDs of projects to associate with the granular scope, when access is `selected_memberships`'
          optional :group_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
            desc: 'IDs of groups to associate with the granular scope, when access is `selected_memberships`'
        end
      end

      def finder_params(current_user)
        user_param =
          if current_user.can_admin_all_resources?
            if params[:user_id].present?
              user = find_pat_user_by_id(params[:user_id])

              not_found! if user.nil?

              { user: user }
            else
              not_found! if params.key?(:user_id)

              {}
            end
          else
            { user: current_user, impersonation: false }
          end

        declared(params, include_missing: false).merge(user_param)
      end

      def find_pat_user_by_id(user_id)
        UserFinder.new(user_id).find_by_id
      end

      def restrict_non_admins!
        return if params[:user_id].blank?

        unauthorized! unless Ability.allowed?(
          current_user,
          :read_personal_access_token,
          find_pat_user_by_id(params[:user_id])
        )
      end

      def find_token(id)
        PersonalAccessToken.find(id) || not_found!
      end

      def project_ids_by_namespace_id_for(tokens)
        namespaces = Array(tokens).flat_map(&:granular_scopes).filter_map(&:namespace)
        project_namespace_ids = namespaces.select { |namespace| namespace.is_a?(::Namespaces::ProjectNamespace) }
          .map(&:id)

        return {} if project_namespace_ids.empty?

        ::Project.ids_by_project_namespace_id(project_namespace_ids)
      end

      def build_granular_scopes(current_user, inputs)
        inputs.flat_map { |input| granular_scope_attrs(current_user, input) }.map { |attrs| ::Authz::GranularScope.new(attrs) }
      end

      def granular_scope_attrs(current_user, input)
        base_attrs = { access: input[:access], permissions: input[:permissions] }

        case input[:access].to_s
        when ::Authz::GranularScope::Access::SELECTED_MEMBERSHIPS.to_s
          selected_memberships_attrs(current_user, input, base_attrs)
        when ::Authz::GranularScope::Access::PERSONAL_PROJECTS.to_s
          [base_attrs.merge(namespace: current_user.namespace)]
        else
          [base_attrs]
        end
      end

      def selected_memberships_attrs(current_user, input, base_attrs)
        groups = Group.id_in(Array(input[:group_ids]))
        projects = Project.id_in(Array(input[:project_ids]))
          .preload(:project_namespace) # rubocop:disable CodeReuse/ActiveRecord -- avoids N+1 loading project_namespace per project

        resource_scope_attrs(current_user, groups, base_attrs) +
          resource_scope_attrs(current_user, projects, base_attrs)
      end

      def resource_scope_attrs(current_user, resources, base_attrs)
        resources.map do |resource|
          boundary = ::Authz::Boundary.for(resource)
          not_found! unless boundary.member?(current_user)

          base_attrs.merge(namespace: boundary.namespace)
        end
      end

      def create_granular_token(current_user, granular_scopes, token_params, target_user: current_user)
        escalation_check = ::Authz::Tokens::PrivilegeEscalationCheck.new(granular_scopes, access_token).execute
        return escalation_check if escalation_check.error?

        ::Authn::PersonalAccessTokens::CreateGranularService.new(
          current_user: current_user,
          target_user: target_user,
          organization: Current.organization,
          params: token_params,
          granular_scopes: granular_scopes
        ).execute
      end

      def revoke_token(token, group: nil, project: nil)
        service = ::PersonalAccessTokens::RevokeService.new(current_user, token: token, group: group,
          project: project).execute

        service.success? ? no_content! : bad_request!(service.message)
      end

      def rotate_token(token, params)
        service = ::PersonalAccessTokens::RotateService.new(current_user, token, nil,
          params.merge(creation_source: PersonalAccessToken::CREATION_SOURCE_API)).execute

        if service.success?
          status :ok

          service.payload[:personal_access_token]
        else
          bad_request!(service.message)
        end
      end

      def rotate_token_for_resource(token, resource, params)
        response = if resource.is_a?(Project)
                     ::ProjectAccessTokens::RotateService.new(
                       current_user, token, resource, params).execute
                   elsif resource.is_a?(Group)
                     ::GroupAccessTokens::RotateService.new(
                       current_user, token, resource, params).execute
                   end

        if response.success?
          status :ok

          response.payload[:personal_access_token]
        else
          bad_request!(response.message)
        end
      end
    end
  end
end
