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
        desc 'Retrieve a personal access token' do
          detail 'Retrieves a specified personal access token by passing it to the API in a header.'
          success code: 200, model: Entities::PersonalAccessTokenWithLastUsedIps
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[access_tokens]
        end
        route_setting :authorization, permissions: :read_personal_access_token, boundary_type: :user
        get 'self' do
          present access_token, with: Entities::PersonalAccessTokenWithLastUsedIps
        end

        desc 'List all token associations' do
          detail 'Lists all groups and projects accessible by the personal access token used to authenticate the ' \
            'request. Generally, this includes any groups or projects that the user is a member of.'
          success code: 200, model: Entities::PersonalAccessToken
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[access_tokens]
        end
        params do
          # rubocop:disable API/AccessLevelStringType -- Introduced before the cop
          optional :min_access_level, type: Integer, values: Gitlab::Access.all_values,
            desc: 'Limit by minimum access level of authenticated user'
          # rubocop:enable API/AccessLevelStringType
          use :pagination
        end
        route_setting :authorization, permissions: :read_personal_access_token, boundary_type: :user
        get 'self/associations' do
          access_token_associations = {
            groups: paginate(load_groups),
            projects: paginate(load_projects)
          }
          present access_token_associations, with: Entities::PersonalAccessTokenAssociations, current_user: current_user
        end

        desc 'Revoke a personal access token' do
          detail 'Revokes a personal access token by passing it to the API in a header.'
          success code: 204
          failure [
            { code: 400, message: 'Bad Request' }
          ]
          tags %w[access_tokens]
        end
        route_setting :authorization, permissions: :revoke_personal_access_token, boundary_type: :user
        delete 'self' do
          revoke_token(access_token)
        end
      end
    end
  end
end
