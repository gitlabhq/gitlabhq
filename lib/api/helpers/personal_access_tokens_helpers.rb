# frozen_string_literal: true

module API
  module Helpers
    module PersonalAccessTokensHelpers
      extend Grape::API::Helpers

      # Every API class that presents personal access tokens reaches granular_scopes_options_for
      # through this module.
      include ::API::Helpers::Authz::GranularScopesHelpers

      params :access_token_params do
        optional :revoked, type: Boolean, desc: 'If `true`, only returns revoked tokens. If `false`, ' \
                                            'only returns tokens that are not revoked.',
          documentation: { example: false }
        optional :state, type: String, desc: 'Return tokens with the specified state.',
          values: %w[active inactive], documentation: { example: 'active' }
        optional :created_before, type: DateTime, desc: 'Return tokens created on or before the specified time.',
          documentation: { example: '2022-01-01T00:00:00Z' }
        optional :created_after, type: DateTime, desc: 'Return tokens created on or after the specified time.',
          documentation: { example: '2021-01-01T00:00:00Z' }
        optional :last_used_before, type: DateTime, desc: 'Return tokens last used on or before the specified time.',
          documentation: { example: '2021-01-01T00:00:00Z' }
        optional :last_used_after, type: DateTime, desc: 'Return tokens last used on or after the specified time.',
          documentation: { example: '2022-01-01T00:00:00Z' }
        optional :expires_before, type: Date, desc: 'Return tokens that expire before the specified date.',
          documentation: { example: '2022-01-01' }
        optional :expires_after, type: Date, desc: 'Return tokens that expire on or after the specified date.',
          documentation: { example: '2021-01-01' }
        optional :search, type: String, desc: 'Return tokens that include the specified value in their ' \
                                          'name.', documentation: { example: 'token' }
        optional :sort, type: String, desc: 'Sort results by the specified field and direction. Possible ' \
                                        'values are `created_asc`, `created_desc`, `expires_asc`, ' \
                                        '`expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, ' \
                                        'and `name_desc`.', documentation: { example: 'created_desc' }
      end

      params :create_personal_access_token_params do
        requires :name, type: String, desc: 'Name of the access token.', documentation: { example: 'My token' }
        optional :description, type: String, desc: 'Description of the access token. Limited to 255 characters.',
          documentation: { example: 'A token used for k8s' }
        optional :expires_at, type: Date, desc: "Expiration date of the access token in ISO format (YYYY-MM-DD). " \
                                            "If undefined, the date is set to the maximum allowable lifetime limit.",
          documentation: { example: '2021-01-31' }
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
