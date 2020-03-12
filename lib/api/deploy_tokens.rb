# frozen_string_literal: true

module API
  class DeployTokens < Grape::API
    include PaginationParams

    helpers do
      def scope_params
        scopes = params.delete(:scopes)

        result_hash = {}
        result_hash[:read_registry] = scopes.include?('read_registry')
        result_hash[:read_repository] = scopes.include?('read_repository')
        result_hash
      end
    end

    desc 'Return all deploy tokens' do
      detail 'This feature was introduced in GitLab 12.9.'
      success Entities::DeployToken
    end
    params do
      use :pagination
    end
    get 'deploy_tokens' do
      service_unavailable! unless Feature.enabled?(:deploy_tokens_api, default_enabled: true)

      authenticated_as_admin!

      present paginate(DeployToken.all), with: Entities::DeployToken
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        service_unavailable! unless Feature.enabled?(:deploy_tokens_api, user_project, default_enabled: true)
      end

      params do
        use :pagination
      end
      desc 'List deploy tokens for a project' do
        detail 'This feature was introduced in GitLab 12.9'
        success Entities::DeployToken
      end
      get ':id/deploy_tokens' do
        authorize!(:read_deploy_token, user_project)

        present paginate(user_project.deploy_tokens), with: Entities::DeployToken
      end

      params do
        requires :name, type: String, desc: "New deploy token's name"
        requires :expires_at, type: DateTime, desc: 'Expiration date for the deploy token. Does not expire if no value is provided.'
        requires :username, type: String, desc: 'Username for deploy token. Default is `gitlab+deploy-token-{n}`'
        requires :scopes, type: Array[String], values: ::DeployToken::AVAILABLE_SCOPES.map(&:to_s),
          desc: 'Indicates the deploy token scopes. Must be at least one of "read_repository" or "read_registry".'
      end
      desc 'Create a project deploy token' do
        detail 'This feature was introduced in GitLab 12.9'
        success Entities::DeployTokenWithToken
      end
      post ':id/deploy_tokens' do
        authorize!(:create_deploy_token, user_project)

        deploy_token = ::Projects::DeployTokens::CreateService.new(
          user_project, current_user, scope_params.merge(declared(params, include_missing: false, include_parent_namespaces: false))
        ).execute

        present deploy_token, with: Entities::DeployTokenWithToken
      end

      desc 'Delete a project deploy token' do
        detail 'This feature was introduced in GitLab 12.9'
      end
      params do
        requires :token_id, type: Integer, desc: 'The deploy token ID'
      end
      delete ':id/deploy_tokens/:token_id' do
        authorize!(:destroy_deploy_token, user_project)

        deploy_token = user_project.project_deploy_tokens
          .find_by_deploy_token_id(params[:token_id])

        not_found!('Deploy Token') unless deploy_token

        deploy_token.destroy
        no_content!
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        service_unavailable! unless Feature.enabled?(:deploy_tokens_api, user_group, default_enabled: true)
      end

      params do
        use :pagination
      end
      desc 'List deploy tokens for a group' do
        detail 'This feature was introduced in GitLab 12.9'
        success Entities::DeployToken
      end
      get ':id/deploy_tokens' do
        authorize!(:read_deploy_token, user_group)

        present paginate(user_group.deploy_tokens), with: Entities::DeployToken
      end

      params do
        requires :name, type: String, desc: 'The name of the deploy token'
        requires :expires_at, type: DateTime, desc: 'Expiration date for the deploy token. Does not expire if no value is provided.'
        requires :username, type: String, desc: 'Username for deploy token. Default is `gitlab+deploy-token-{n}`'
        requires :scopes, type: Array[String], values: ::DeployToken::AVAILABLE_SCOPES.map(&:to_s),
          desc: 'Indicates the deploy token scopes. Must be at least one of "read_repository" or "read_registry".'
      end
      desc 'Create a group deploy token' do
        detail 'This feature was introduced in GitLab 12.9'
        success Entities::DeployTokenWithToken
      end
      post ':id/deploy_tokens' do
        authorize!(:create_deploy_token, user_group)

        deploy_token = ::Groups::DeployTokens::CreateService.new(
          user_group, current_user, scope_params.merge(declared(params, include_missing: false, include_parent_namespaces: false))
        ).execute

        present deploy_token, with: Entities::DeployTokenWithToken
      end

      desc 'Delete a group deploy token' do
        detail 'This feature was introduced in GitLab 12.9'
      end
      delete ':id/deploy_tokens/:token_id' do
        authorize!(:destroy_deploy_token, user_group)

        deploy_token = user_group.group_deploy_tokens
          .find_by_deploy_token_id!(params[:token_id])

        destroy_conditionally!(deploy_token)
      end
    end
  end
end
