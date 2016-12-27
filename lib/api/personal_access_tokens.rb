module API
  class PersonalAccessTokens < Grape::API
    before { authenticate! }

    resource :personal_access_tokens do
      desc 'Retrieve personal access tokens'
      params do
        optional :state, type: String, default: 'all', values: %w[all active inactive], desc: 'Filters (all|active|inactive) personal_access_tokens'
      end
      get do
        personal_access_tokens = current_user.personal_access_tokens

        case params[:state]
        when "active"
          personal_access_tokens = personal_access_tokens.active
        when "inactive"
          personal_access_tokens = personal_access_tokens.inactive
        end

        present personal_access_tokens, with: Entities::BasicPersonalAccessToken
      end

      desc 'Create a personal access token'
      params do
        requires :name, type: String, desc: 'The name of the personal access token'
        optional :expires_at, type: Date, desc: 'The expiration date in the format YEAR-MONTH-DAY of the personal access token'
        optional :scopes, type: Array, desc: 'The array of scopes of the personal access token'
      end
      post do
        parameters = declared_params(include_missing: false)
        parameters[:user_id] = current_user.id

        personal_access_token = PersonalAccessToken.generate(parameters)

        if personal_access_token.save
          present personal_access_token, with: Entities::PersonalAccessToken
        else
          render_validation_error!(personal_access_token)
        end
      end

      desc 'Revoke a personal access token'
      params do
        requires :personal_access_token_id, type: Integer, desc: 'The ID of the personal access token'
      end
      delete ':personal_access_token_id' do
        personal_access_token = PersonalAccessToken.find_by(id: params[:personal_access_token_id], user_id: current_user.id)
        not_found!('PersonalAccessToken') unless personal_access_token

        personal_access_token.revoke!

        present personal_access_token, with: Entities::BasicPersonalAccessToken
      end
    end
  end
end
