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
      optional :user_id, type: Integer, desc: 'User ID'

      use :pagination
    end

    before do
      authenticate!
      restrict_non_admins! unless current_user.admin?
    end

    helpers do
      def finder_params(current_user)
        current_user.admin? ? { user: user(params[:user_id]) } : { user: current_user, impersonation: false }
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
    end

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
          current_user.admin? ? not_found! : unauthorized!
        end
      end

      delete 'self' do
        revoke_token(access_token)
      end

      delete ':id' do
        token = find_token(params[:id])

        revoke_token(token)
      end
    end
  end
end
