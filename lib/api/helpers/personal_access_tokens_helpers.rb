# frozen_string_literal: true

module API
  module Helpers
    module PersonalAccessTokensHelpers
      extend Grape::API::Helpers

      params :access_token_params do
        optional :revoked, type: Boolean, desc: 'Filter tokens where revoked state matches parameter',
          documentation: { example: false }
        optional :state, type: String, desc: 'Filter tokens which are either active or not',
          values: %w[active inactive], documentation: { example: 'active' }
        optional :created_before, type: DateTime, desc: 'Filter tokens which were created before given datetime',
          documentation: { example: '2022-01-01' }
        optional :created_after, type: DateTime, desc: 'Filter tokens which were created after given datetime',
          documentation: { example: '2021-01-01' }
        optional :last_used_before, type: DateTime, desc: 'Filter tokens which were used before given datetime',
          documentation: { example: '2021-01-01' }
        optional :last_used_after, type: DateTime, desc: 'Filter tokens which were used after given datetime',
          documentation: { example: '2022-01-01' }
        optional :search, type: String, desc: 'Filters tokens by name', documentation: { example: 'token' }
        optional :sort, type: String, desc: 'Sort tokens', documentation: { example: 'created_at_desc' }
      end

      def finder_params(current_user)
        user_param =
          if current_user.can_admin_all_resources?
            if params[:user_id].present?
              user = user(params[:user_id])

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

      def user(user_id)
        UserFinder.new(user_id).find_by_id
      end

      def restrict_non_admins!
        return if params[:user_id].blank?

        unauthorized! unless Ability.allowed?(current_user, :read_user_personal_access_tokens, user(params[:user_id]))
      end

      def find_token(id)
        PersonalAccessToken.find(id) || not_found!
      end

      def revoke_token(token)
        service = ::PersonalAccessTokens::RevokeService.new(current_user, token: token).execute

        service.success? ? no_content! : bad_request!(nil)
      end

      def rotate_token(token, params)
        service = ::PersonalAccessTokens::RotateService.new(current_user, token, nil, params).execute

        if service.success?
          status :ok

          service.payload[:personal_access_token]
        else
          bad_request!(service.message)
        end
      end
    end
  end
end
