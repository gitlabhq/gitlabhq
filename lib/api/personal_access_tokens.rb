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
      desc 'List personal access tokens' do
        detail 'Get all personal access tokens the authenticated user has access to.'
        is_array true
        success Entities::PersonalAccessToken
        tags %w[personal_access_tokens]
        failure [
          { code: 401, message: 'Unauthorized' }
        ]
      end
      params do
        optional :user_id, type: Integer, desc: 'Filter PATs by User ID', documentation: { example: 2 }
        use :access_token_params
        use :pagination
      end
      get do
        tokens = PersonalAccessTokensFinder.new(finder_params(current_user), current_user).execute

        present paginate(tokens), with: Entities::PersonalAccessToken
      end

      desc 'Get single personal access token' do
        detail 'Get a personal access token by using the ID of the personal access token.'
        success Entities::PersonalAccessTokenWithLastUsedIps
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      get ':id' do
        token = PersonalAccessToken.find_by_id(params[:id])

        allowed = Ability.allowed?(current_user, :read_user_personal_access_tokens, token&.user)

        if allowed
          present token, with: Entities::PersonalAccessTokenWithLastUsedIps
        else
          # Only admins should be informed if the token doesn't exist
          current_user.can_admin_all_resources? ? not_found! : unauthorized!
        end
      end

      desc 'Rotate personal access token' do
        detail 'Roates a personal access token.'
        success Entities::PersonalAccessTokenWithToken
      end
      params do
        optional :expires_at,
          type: Date,
          desc: "The expiration date of the token",
          documentation: { example: '2021-01-31' }
      end
      post ':id/rotate' do
        token = PersonalAccessToken.find_by_id(params[:id])

        if Ability.allowed?(current_user, :manage_user_personal_access_token, token&.user)
          new_token = rotate_token(token, declared_params)

          present new_token, with: Entities::PersonalAccessTokenWithToken
        else
          # Only admins should be informed if the token doesn't exist
          current_user.can_admin_all_resources? ? not_found! : unauthorized!
        end
      end

      desc 'Revoke a personal access token' do
        detail 'Revoke a personal access token by using the ID of the personal access token.'
        success code: 204
        failure [
          { code: 400, message: 'Bad Request' }
        ]
      end
      delete ':id' do
        token = find_token(params[:id])

        revoke_token(token)
      end
    end
  end
end
