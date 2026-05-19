# frozen_string_literal: true

module API
  class GroupServiceAccounts < ::API::Base
    include PaginationParams

    feature_category :user_management

    before do
      authenticate!
      authorize! :admin_service_accounts, user_group
      set_current_organization
    end

    helpers ::API::Helpers::PersonalAccessTokensHelpers
    helpers do
      def user
        user_group.provisioned_users.find_by_id(params[:user_id])
      end

      def validate_service_account_user
        not_found!('User') unless user
        bad_request!("User is not of type Service Account") unless user.service_account?
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
    end

    resource 'groups/:id', requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource :service_accounts do
        desc 'Create a group service account' do
          detail 'Creates a service account in the specified group'
          success Entities::ServiceAccount
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 Group not found' }
          ]
          tags ['service_accounts']
        end

        params do
          optional :name, type: String, desc: 'Name of the user'
          optional :username, type: String, desc: 'Username of the user'
          optional :email, type: String, desc: 'Custom email address for the user'
        end

        route_setting :authorization, permissions: :create_service_account, boundary_type: :group
        post do
          check_rate_limit!(:service_account_creation, scope: current_user)

          organization_id = user_group.organization_id
          service_params = declared_params.merge({ organization_id: organization_id, namespace_id: user_group.id })

          response = ::Namespaces::ServiceAccounts::GroupCreateService
                       .new(current_user, service_params)
                       .execute

          if response.status == :success
            present response.payload[:user], with: Entities::ServiceAccount, current_user: current_user
          else
            bad_request!(response.message)
          end
        end

        desc 'List all group service accounts' do
          detail 'Lists all service accounts for a specified group'
          success Entities::ServiceAccount
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 Group not found' }
          ]
          tags ['service_accounts']
        end

        params do
          use :pagination
          optional :order_by, type: String, values: %w[id username], default: 'id',
            desc: 'Attribute to sort by'
          optional :sort, type: String, values: %w[asc desc], default: 'desc', desc: 'Order of sorting'
        end

        # rubocop: disable CodeReuse/ActiveRecord -- for the user or reorder
        route_setting :authorization, permissions: :read_service_account, boundary_type: :group
        get do
          users = user_group.service_accounts

          users = users.reorder(params[:order_by] => params[:sort])

          present paginate_with_strategies(users), with: Entities::ServiceAccount, current_user: current_user
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Delete a group service account.' do
          detail 'Deletes a service account from a specified group. Available only for group owners and admins.'
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 Group not found' }
          ]
          tags ['service_accounts']
        end

        params do
          requires :user_id, type: Integer, desc: 'The ID of the service account'
          optional :hard_delete, type: Boolean, desc: "Whether to remove a user's contributions"
        end

        route_setting :authorization, permissions: :delete_service_account, boundary_type: :group
        delete ":user_id" do
          validate_service_account_user

          delete_params = declared_params(include_missing: false)

          unless user.can_be_removed? || delete_params[:hard_delete]
            conflict!('User cannot be removed while is the sole-owner of a group')
          end

          destroy_conditionally!(user) do
            ::Namespaces::ServiceAccounts::GroupDeleteService
            .new(current_user, user)
            .execute(delete_params)
          end
        end

        desc 'Update a group service account' do
          detail 'Update a specified group service account.'
          success Entities::ServiceAccount
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 User not found' }
          ]
          tags ['service_accounts']
        end

        params do
          requires :user_id, type: Integer, desc: 'The ID of the service account'
          optional :name, type: String, desc: 'Name of the user'
          optional :username, type: String, desc: 'Username of the user'
          optional :email, type: String, desc: 'Custom email address for the user'
        end

        route_setting :authorization, permissions: :update_service_account, boundary_type: :group
        patch ":user_id" do
          validate_service_account_user

          update_params = declared_params(include_missing: false).merge({ group_id: user_group.id })

          response = ::Namespaces::ServiceAccounts::GroupUpdateService
                       .new(current_user, user, update_params)
                       .execute

          if response.success?
            present response.payload[:user], with: Entities::ServiceAccount, current_user: current_user
          else
            render_api_error!(response.message, response.reason)
          end
        end

        resource ":user_id/personal_access_tokens" do
          desc 'List all personal access tokens for a group service account' do
            detail 'Lists all personal access tokens for a specified group service account'
            success Entities::PersonalAccessToken
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: '401 Unauthorized' },
              { code: 404, message: '404 Group Not Found' },
              { code: 403, message: 'Forbidden' }
            ]
            tags %w[access_tokens service_accounts]
          end

          params do
            use :access_token_params
            use :pagination
          end

          route_setting :authorization, permissions: :read_service_account_personal_access_token, boundary_type: :group
          get do
            validate_service_account_user

            merged_params = declared(params, include_missing: false).merge({ user: user, impersonation: false })
            service_account_pats = ::PersonalAccessTokensFinder.new(merged_params, user).execute

            present paginate_with_strategies(service_account_pats), with: Entities::PersonalAccessToken
          end

          desc 'Create a personal access token for a group service account.' do
            detail 'Creates a personal access token for a specified group service account.
              Requires the group Owner role. This feature was introduced in GitLab 16.1.'
            success Entities::PersonalAccessTokenWithToken
            tags %w[access_tokens service_accounts]
          end

          params do
            use :create_personal_access_token_params
            requires :scopes, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
              values: ::Gitlab::Auth.all_available_scopes.map(&:to_s),
              desc: 'The array of scopes of the personal access token'
          end

          route_setting :authorization, permissions: :create_service_account_personal_access_token,
            boundary_type: :group
          post do
            validate_service_account_user

            response = ::PersonalAccessTokens::CreateService.new(
              current_user: current_user, target_user: user, organization_id: Current.organization.id,
              params: declared_params.merge(
                group: user_group,
                creation_source: PersonalAccessToken::CREATION_SOURCE_API
              )
            ).execute

            if response.success?
              present response.payload[:personal_access_token], with: Entities::PersonalAccessTokenWithToken
            else
              render_api_error!(response.message, response.http_status || :unprocessable_entity)
            end
          end

          desc 'Revoke a personal access token for a group service account' do
            detail 'Revokes a specified personal access token for a group service account.'
            success code: 204
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' }
            ]
            tags %w[access_tokens service_accounts]
          end
          route_setting :authorization, permissions: :revoke_service_account_personal_access_token,
            boundary_type: :group
          delete ':token_id' do
            validate_service_account_user

            token_id = params[:token_id]
            token = user.personal_access_tokens.find_by_id(token_id)

            if token
              revoke_token(token, group: user_group)
            else
              not_found!('Personal Access Token')
            end
          end

          desc 'Rotate personal access token for group service account' do
            detail 'Rotates a specified personal access token for a group service account.'
            success Entities::PersonalAccessTokenWithToken
            tags %w[access_tokens service_accounts]
          end
          params do
            optional :expires_at,
              type: Date,
              desc: "The expiration date of the token",
              documentation: { example: '2021-01-31' }
          end
          route_setting :authorization, permissions: :rotate_service_account_personal_access_token,
            boundary_type: :group
          post ':token_id/rotate' do
            validate_service_account_user

            token = PersonalAccessToken.find_by_id(params[:token_id])

            if token&.user == user
              response = ::PersonalAccessTokens::RotateService
                           .new(current_user, token, nil,
                             declared_params.merge(creation_source: PersonalAccessToken::CREATION_SOURCE_API))
                           .execute

              if response.success?
                status :ok

                new_token = response.payload[:personal_access_token]
                present new_token, with: Entities::PersonalAccessTokenWithToken
              else
                bad_request!(response.message)
              end
            else
              not_found!
            end
          end
        end
      end
    end
  end
end
