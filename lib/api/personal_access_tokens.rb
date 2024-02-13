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
        optional :revoked, type: Boolean, desc: 'Filter PATs where revoked state matches parameter',
                           documentation: { example: false }
        optional :state, type: String, desc: 'Filter PATs which are either active or not',
                         values: %w[active inactive], documentation: { example: 'active' }
        optional :created_before, type: DateTime, desc: 'Filter PATs which were created before given datetime',
                                  documentation: { example: '2022-01-01' }
        optional :created_after, type: DateTime, desc: 'Filter PATs which were created after given datetime',
                                 documentation: { example: '2021-01-01' }
        optional :last_used_before, type: DateTime, desc: 'Filter PATs which were used before given datetime',
                                    documentation: { example: '2021-01-01' }
        optional :last_used_after, type: DateTime, desc: 'Filter PATs which were used after given datetime',
                                   documentation: { example: '2022-01-01' }
        optional :search, type: String, desc: 'Filters PATs by its name', documentation: { example: 'token' }

        use :pagination
      end
      get do
        tokens = PersonalAccessTokensFinder.new(finder_params(current_user), current_user).execute

        present paginate(tokens), with: Entities::PersonalAccessToken
      end

      desc 'Get single personal access token' do
        detail 'Get a personal access token by using the ID of the personal access token.'
        success Entities::PersonalAccessToken
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
      end
      get ':id' do
        token = PersonalAccessToken.find_by_id(params[:id])

        allowed = Ability.allowed?(current_user, :read_user_personal_access_tokens, token&.user)

        if allowed
          present token, with: Entities::PersonalAccessToken
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
