# frozen_string_literal: true

module API
  class PersonalAccessTokens < ::API::Base
    include ::API::PaginationParams

    feature_category :authentication_and_authorization

    desc 'Get all Personal Access Tokens' do
      detail 'This feature was added in GitLab 13.3'
      success Entities::PersonalAccessToken
    end
    params do
      optional :user_id, type: Integer, desc: 'Filter PATs by User ID'
      optional :revoked, type: Boolean, desc: 'Filter PATs where revoked state matches parameter'
      optional :state, type: String, desc: 'Filter PATs which are either active or not',
                       values: %w[active inactive]
      optional :created_before, type: DateTime, desc: 'Filter PATs which were created before given datetime'
      optional :created_after, type: DateTime, desc: 'Filter PATs which were created after given datetime'
      optional :last_used_before, type: DateTime, desc: 'Filter PATs which were used before given datetime'
      optional :last_used_after, type: DateTime, desc: 'Filter PATs which were used after given datetime'
      optional :search, type: String, desc: 'Filters PATs by its name'

      use :pagination
    end

    before do
      authenticate!
      restrict_non_admins! unless current_user.can_admin_all_resources?
    end

    helpers ::API::Helpers::PersonalAccessTokensHelpers

    resources :personal_access_tokens do
      get do
        tokens = PersonalAccessTokensFinder.new(finder_params(current_user), current_user).execute

        present paginate(tokens), with: Entities::PersonalAccessToken
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

      delete ':id' do
        token = find_token(params[:id])

        revoke_token(token)
      end
    end
  end
end
