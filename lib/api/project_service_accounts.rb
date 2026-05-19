# frozen_string_literal: true

module API
  class ProjectServiceAccounts < ::API::Base
    include PaginationParams

    feature_category :user_management

    before do
      authenticate!
      authorize! :admin_service_accounts, user_project
      set_current_organization
    end

    helpers ::API::Helpers::PersonalAccessTokensHelpers
    helpers do
      def service_account
        user_project.service_accounts.find_by_id(params[:user_id])
      end

      def validate_service_account
        not_found!('User') unless service_account
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end

    resource 'projects/:id', requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      resource :service_accounts do
        desc 'Create a project service account' do
          detail 'Creates a service account in the specified project'
          success Entities::ServiceAccount
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 Project not found' }
          ]
          tags ['service_accounts']
        end

        params do
          optional :name, type: String, desc: 'Name of the user'
          optional :username, type: String, desc: 'Username of the user'
          optional :email, type: String, desc: 'Custom email address for the user'
        end

        post do
          check_rate_limit!(:service_account_creation, scope: current_user)

          organization_id = user_project.organization_id
          service_params = declared_params.merge({
            organization_id: organization_id,
            project_id: user_project.id
          })

          response = ::Namespaces::ServiceAccounts::ProjectCreateService
                       .new(current_user, service_params)
                       .execute

          if response.status == :success
            present response.payload[:user], with: Entities::ServiceAccount, current_user: current_user
          else
            bad_request!(response.message)
          end
        end

        desc 'List all project service accounts' do
          detail 'Lists all service accounts for a specified project'
          success Entities::ServiceAccount
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 Project not found' }
          ]
          tags ['service_accounts']
        end

        params do
          use :pagination
          optional :order_by, type: String, values: %w[id username], default: 'id',
            desc: 'Attribute to sort by'
          optional :sort, type: String, values: %w[asc desc], default: 'desc', desc: 'Order of sorting'
        end

        # rubocop: disable CodeReuse/ActiveRecord -- for reorder
        get do
          service_accounts = user_project.service_accounts

          service_accounts = service_accounts.reorder(params[:order_by] => params[:sort])

          present paginate_with_strategies(service_accounts), with: Entities::ServiceAccount, current_user: current_user
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Delete a project service account' do
          detail 'Deletes a service account from a specified project.
            Available only for project Owners or Maintainers, and administrators.'
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 Project not found' }
          ]
          tags ['service_accounts']
          success code: 204
        end

        params do
          requires :user_id, type: Integer, desc: 'The ID of the service account'
          optional :hard_delete, type: Boolean, desc: "Whether to remove a user's contributions"
        end

        delete ":user_id" do
          validate_service_account

          delete_params = declared_params(include_missing: false)

          destroy_conditionally!(service_account) do
            ::Namespaces::ServiceAccounts::ProjectDeleteService
              .new(current_user, service_account)
              .execute(delete_params)
          end
        end

        desc 'Update a project service account' do
          detail 'Update a specified project service account.'
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

        patch ":user_id" do
          validate_service_account

          update_params = declared_params(include_missing: false).merge({ project_id: user_project.id })

          response = ::Namespaces::ServiceAccounts::ProjectUpdateService
                       .new(current_user, service_account, update_params)
                       .execute

          if response.success?
            present response.payload[:user], with: Entities::ServiceAccount, current_user: current_user
          else
            render_api_error!(response.message, response.reason)
          end
        end

        resource ":user_id/personal_access_tokens" do
          desc 'List all personal access tokens for a project service account' do
            detail 'Lists all personal access tokens for a specified project service account'
            success Entities::PersonalAccessToken
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: '401 Unauthorized' },
              { code: 404, message: '404 Project Not Found' },
              { code: 403, message: 'Forbidden' }
            ]
            tags %w[access_tokens service_accounts]
          end

          params do
            use :access_token_params
            use :pagination
          end

          get do
            validate_service_account

            service_account_pats = ::PersonalAccessTokensFinder.new(finder_params(service_account),
              service_account).execute

            present paginate_with_strategies(service_account_pats), with: Entities::PersonalAccessToken
          end

          desc 'Create a personal access token for a project service account.' do
            detail 'Creates a personal access token for a specified project service account.
              Available only for project Owners or Maintainers.'
            success Entities::PersonalAccessTokenWithToken
            tags %w[access_tokens service_accounts]
          end

          params do
            use :create_personal_access_token_params
            requires :scopes, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
              values: ::Gitlab::Auth.all_available_scopes.map(&:to_s),
              desc: 'The array of scopes of the personal access token'
          end

          post do
            validate_service_account

            response = ::PersonalAccessTokens::CreateService.new(
              current_user: current_user, target_user: service_account, organization_id: Current.organization.id,
              params: declared_params.merge(
                project: user_project,
                creation_source: PersonalAccessToken::CREATION_SOURCE_API
              )
            ).execute

            if response.success?
              present response.payload[:personal_access_token], with: Entities::PersonalAccessTokenWithToken
            else
              render_api_error!(response.message, response.http_status || :unprocessable_entity)
            end
          end

          desc 'Revoke a personal access token for a project service account' do
            detail 'Revokes a specified personal access token for a project service account.'
            success code: 204
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' }
            ]
            tags %w[access_tokens service_accounts]
          end

          delete ':token_id' do
            validate_service_account

            token_id = params[:token_id]
            token = service_account.personal_access_tokens.find_by_id(token_id)

            if token
              revoke_token(token, project: user_project)
            else
              not_found!('Personal Access Token')
            end
          end

          desc 'Rotate a personal access token for a project service account' do
            detail 'Rotates a specified personal access token for a project service account.'
            success Entities::PersonalAccessTokenWithToken
            tags %w[access_tokens service_accounts]
          end

          params do
            optional :expires_at,
              type: Date,
              desc: "The expiration date of the token",
              documentation: { example: '2021-01-31' }
          end

          post ':token_id/rotate' do
            validate_service_account

            token = service_account.personal_access_tokens.find_by_id(params[:token_id])

            if token
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
              not_found!('Personal Access Token')
            end
          end
        end
      end
    end
  end
end
