# frozen_string_literal: true

module API
  class PersonalAccessTokens < ::API::Base
    include ::API::PaginationParams

    feature_category :system_access

    before do
      authenticate!
      restrict_non_admins! unless current_user.can_admin_all_resources?
    end

    helpers ::API::Helpers::PersonalAccessTokensHelpers

    resources :personal_access_tokens do
      desc 'List all personal access tokens' do
        detail 'Lists all personal access tokens accessible by the authenticated user. For administrators, returns ' \
          'all personal access tokens in the instance. For non-administrators, returns all of their personal access ' \
          'tokens.'
        is_array true
        success Entities::PersonalAccessTokenWithLastUsedIps
        tags %w[access_tokens]
        failure [
          { code: 401, message: 'Unauthorized' }
        ]
      end
      params do
        optional :user_id, type: Integer, desc: 'Filter PATs by User ID', documentation: { example: 2 }
        use :access_token_params
        use :pagination
      end
      route_setting :authorization, permissions: :read_personal_access_token, boundary_type: :user
      get do
        tokens = PersonalAccessTokensFinder.new(finder_params(current_user), current_user).execute

        present paginate(tokens), with: Entities::PersonalAccessTokenWithLastUsedIps
      end

      desc 'Retrieve a personal access token' do
        detail 'Retrieves details for a specified personal access token. Administrators can retrieve details on any ' \
          'token. Non-administrators can only retrieve details on their own tokens.'
        success Entities::PersonalAccessTokenWithLastUsedIps
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[access_tokens]
      end
      route_setting :authorization, permissions: :read_personal_access_token, boundary_type: :user
      get ':id' do
        token = PersonalAccessToken.find_by_id(params[:id])

        allowed = Ability.allowed?(current_user, :read_personal_access_token, token&.user)

        if allowed
          present token, with: Entities::PersonalAccessTokenWithLastUsedIps
        else
          # Only admins should be informed if the token doesn't exist
          current_user.can_admin_all_resources? ? not_found! : unauthorized!
        end
      end

      desc 'Rotate a personal access token' do
        detail 'Rotates a specified personal access token. This revokes the previous token and creates a token that ' \
          'expires after one week. Administrators can revoke tokens for any user. Non-administrators can only revoke ' \
          'their own tokens.'
        success Entities::PersonalAccessTokenWithToken
        tags %w[access_tokens]
      end
      params do
        optional :expires_at,
          type: Date,
          desc: "The expiration date of the token",
          documentation: { example: '2021-01-31' }
      end
      route_setting :authorization, permissions: :rotate_personal_access_token, boundary_type: :user
      post ':id/rotate' do
        token = PersonalAccessToken.find_by_id(params[:id])

        if Ability.allowed?(current_user, :rotate_personal_access_token, token&.user)
          new_token = rotate_token(token, declared_params)

          present new_token, with: Entities::PersonalAccessTokenWithToken
        else
          # Only admins should be informed if the token doesn't exist
          current_user.can_admin_all_resources? ? not_found! : unauthorized!
        end
      end

      desc 'Revoke a personal access token' do
        detail 'Revokes a specified personal access token. Administrators can revoke tokens for any user. ' \
          'Non-administrators can only revoke their own tokens.'
        success code: 204
        failure [
          { code: 400, message: 'Bad Request' }
        ]
        tags %w[access_tokens]
      end
      route_setting :authorization, permissions: :revoke_personal_access_token, boundary_type: :user
      delete ':id' do
        token = find_token(params[:id])

        revoke_token(token)
      end
    end
  end
end
