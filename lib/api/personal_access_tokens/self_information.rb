# frozen_string_literal: true

module API
  class PersonalAccessTokens
    class SelfInformation < ::API::Base
      include APIGuard
      include PaginationParams

      feature_category :system_access

      helpers ::API::Helpers::PersonalAccessTokensHelpers

      # As any token regardless of `scope` should be able to view/revoke itself
      # all available scopes are allowed for this API class.
      # Please be aware of the permissive scope when adding new endpoints to this class.
      allow_access_with_scope(Gitlab::Auth.all_available_scopes)

      before { authenticate! }
      before do
        unless ::Current.token_info[:token_type] == 'PersonalAccessToken'
          bad_request!("This endpoint requires token type to be a personal access token")
        end
      end

      helpers do
        def load_groups
          finder_params = {}
          finder_params[:min_access_level] = params[:min_access_level] if params[:min_access_level]
          GroupsFinder.new(current_user, finder_params).execute
        end

        def load_projects
          finder_params = {}
          finder_params[:min_access_level] = params[:min_access_level] if params[:min_access_level]
          ProjectsFinder.new(current_user: current_user, params: finder_params).execute
        end
      end

      resource :personal_access_tokens do
        desc "Get single personal access token" do
          detail 'Get the details of a personal access token by passing it to the API in a header'
          success code: 200, model: Entities::PersonalAccessToken
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[personal_access_tokens]
        end
        get 'self' do
          present access_token, with: Entities::PersonalAccessToken
        end

        desc "Return personal access token associations" do
          detail 'Get groups and projects this personal access token can access by passing it to the API in a header'
          success code: 200, model: Entities::PersonalAccessToken
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[personal_access_tokens]
        end
        params do
          optional :min_access_level, type: Integer, values: Gitlab::Access.all_values,
            desc: 'Limit by minimum access level of authenticated user'
          use :pagination
        end
        get 'self/associations' do
          access_token_associations = {
            groups: paginate(load_groups),
            projects: paginate(load_projects)
          }
          present access_token_associations, with: Entities::PersonalAccessTokenAssociations, current_user: current_user
        end

        desc "Revoke a personal access token" do
          detail 'Revoke a personal access token by passing it to the API in a header'
          success code: 204
          failure [
            { code: 400, message: 'Bad Request' }
          ]
          tags %w[personal_access_tokens]
        end
        delete 'self' do
          revoke_token(access_token)
        end
      end
    end
  end
end
