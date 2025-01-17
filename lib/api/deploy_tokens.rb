# frozen_string_literal: true

module API
  class DeployTokens < ::API::Base
    include PaginationParams

    deploy_tokens_tags = %w[deploy_tokens]

    feature_category :continuous_delivery
    urgency :low

    helpers do
      def scope_params
        scopes = params.delete(:scopes)

        result_hash = Hashie::Mash.new
        result_hash[:read_registry] = scopes.include?('read_registry')
        result_hash[:write_registry] = scopes.include?('write_registry')
        result_hash[:read_package_registry] = scopes.include?('read_package_registry')
        result_hash[:write_package_registry] = scopes.include?('write_package_registry')
        result_hash[:read_repository] = scopes.include?('read_repository')
        result_hash[:read_virtual_registry] = scopes.include?('read_virtual_registry')
        result_hash[:write_virtual_registry] = scopes.include?('write_virtual_registry')
        result_hash
      end

      params :filter_params do
        optional :active, type: Boolean, desc: 'Limit by active status'
      end
    end

    desc 'List all deploy tokens' do
      detail 'Get a list of all deploy tokens across the GitLab instance. This endpoint requires administrator access. This feature was introduced in GitLab 12.9.'
      success Entities::DeployToken
      failure [
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' }
      ]
      is_array true
      tags deploy_tokens_tags
    end
    params do
      use :pagination
      use :filter_params
    end
    get 'deploy_tokens' do
      authenticated_as_admin!

      deploy_tokens = ::DeployTokens::TokensFinder.new(
        current_user,
        :all,
        declared_params
      ).execute

      present paginate(deploy_tokens), with: Entities::DeployToken
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      params do
        use :pagination
        use :filter_params
      end
      desc 'List project deploy tokens' do
        detail "Get a list of a project's deploy tokens. This feature was introduced in GitLab 12.9."
        success Entities::DeployToken
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags deploy_tokens_tags
      end
      get ':id/deploy_tokens' do
        authorize!(:read_deploy_token, user_project)

        deploy_tokens = ::DeployTokens::TokensFinder.new(
          current_user,
          user_project,
          declared_params
        ).execute

        present paginate(deploy_tokens), with: Entities::DeployToken
      end

      params do
        requires :name, type: String, desc: "New deploy token's name"
        requires :scopes,
          type: Array[String],
          coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
          values: ::DeployToken::AVAILABLE_SCOPES.map(&:to_s),
          desc: 'Indicates the deploy token scopes. Must be at least one of `read_repository`, `read_registry`, `write_registry`, `read_package_registry`, `write_package_registry`, `read_virtual_registry`, or `write_virtual_registry`.'
        optional :expires_at, type: DateTime, desc: 'Expiration date for the deploy token. Does not expire if no value is provided. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`).'
        optional :username, type: String, desc: 'Username for deploy token. Default is `gitlab+deploy-token-{n}`'
      end
      desc 'Create a project deploy token' do
        detail 'Creates a new deploy token for a project. This feature was introduced in GitLab 12.9.'
        success Entities::DeployTokenWithToken
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_tokens_tags
      end
      post ':id/deploy_tokens' do
        authorize!(:create_deploy_token, user_project)

        result = ::Projects::DeployTokens::CreateService.new(
          user_project, current_user, scope_params.merge(declared(params, include_missing: false, include_parent_namespaces: false))
        ).execute

        if result[:status] == :success
          present result[:deploy_token], with: Entities::DeployTokenWithToken
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Get a project deploy token' do
        detail "Get a single project's deploy token by ID. This feature was introduced in GitLab 14.9."
        success Entities::DeployToken
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_tokens_tags
      end
      params do
        requires :token_id, type: Integer, desc: 'The ID of the deploy token'
      end
      get ':id/deploy_tokens/:token_id' do
        authorize!(:read_deploy_token, user_project)

        deploy_token = user_project.deploy_tokens.find(params[:token_id])

        present deploy_token, with: Entities::DeployToken
      end

      desc 'Delete a project deploy token' do
        detail 'This feature was introduced in GitLab 12.9.'
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_tokens_tags
      end
      params do
        requires :token_id, type: Integer, desc: 'The ID of the deploy token'
      end
      delete ':id/deploy_tokens/:token_id' do
        authorize!(:destroy_deploy_token, user_project)

        ::Projects::DeployTokens::DestroyService.new(
          user_project, current_user, token_id: params[:token_id]
        ).execute

        no_content!
      end
    end

    params do
      requires :id, types: [Integer, String], desc: 'The ID or URL-encoded path of the group owned by the authenticated user'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      params do
        use :pagination
        use :filter_params
      end
      desc 'List group deploy tokens' do
        detail "Get a list of a group's deploy tokens. This feature was introduced in GitLab 12.9."
        success Entities::DeployToken
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags deploy_tokens_tags
      end
      get ':id/deploy_tokens' do
        authorize!(:read_deploy_token, user_group)

        deploy_tokens = ::DeployTokens::TokensFinder.new(
          current_user,
          user_group,
          declared_params
        ).execute

        present paginate(deploy_tokens), with: Entities::DeployToken
      end

      params do
        requires :name, type: String, desc: "New deploy token's name"
        requires :scopes,
          type: Array[String],
          coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
          values: ::DeployToken::AVAILABLE_SCOPES.map(&:to_s),
          desc: 'Indicates the deploy token scopes. Must be at least one of `read_repository`, `read_registry`, `write_registry`, `read_package_registry`, or `write_package_registry`'
        optional :expires_at, type: DateTime, desc: 'Expiration date for the deploy token. Does not expire if no value is provided. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`)'
        optional :username, type: String, desc: 'Username for deploy token. Default is `gitlab+deploy-token-{n}`'
      end
      desc 'Create a group deploy token' do
        detail 'Creates a new deploy token for a group. This feature was introduced in GitLab 12.9.'
        success Entities::DeployTokenWithToken
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_tokens_tags
      end
      post ':id/deploy_tokens' do
        authorize!(:create_deploy_token, user_group)

        result = ::Groups::DeployTokens::CreateService.new(
          user_group, current_user, scope_params.merge(declared(params, include_missing: false, include_parent_namespaces: false))
        ).execute

        if result[:status] == :success
          present result[:deploy_token], with: Entities::DeployTokenWithToken
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Get a group deploy token' do
        detail "Get a single group's deploy token by ID. This feature was introduced in GitLab 14.9. "
        success Entities::DeployToken
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_tokens_tags
      end
      params do
        requires :token_id, type: Integer, desc: 'The ID of the deploy token'
      end
      get ':id/deploy_tokens/:token_id' do
        authorize!(:read_deploy_token, user_group)

        deploy_token = user_group.deploy_tokens.find(params[:token_id])

        present deploy_token, with: Entities::DeployToken
      end

      desc 'Delete a group deploy token' do
        detail 'Removes a deploy token from the group. This feature was introduced in GitLab 12.9.'
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_tokens_tags
      end
      params do
        requires :token_id, type: Integer, desc: 'The ID of the deploy token'
      end
      delete ':id/deploy_tokens/:token_id' do
        authorize!(:destroy_deploy_token, user_group)

        ::Groups::DeployTokens::DestroyService.new(
          user_group, current_user, token_id: params[:token_id]
        ).execute

        no_content!
      end
    end
  end
end
